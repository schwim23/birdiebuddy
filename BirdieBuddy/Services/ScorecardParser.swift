import Vision
import UIKit

/// On-device OCR result from scanning a paper scorecard photo.
struct ScorecardScanResult {
    var courseName: String?
    var slopeRating: Int?
    var courseRatingTimes10: Int?   // stored ×10, e.g. 724 → "72.4"
    var parValues: [Int]?           // exactly 18 values when found
    var handicapValues: [Int]?      // exactly 18 values when found

    var foundAnything: Bool {
        courseName != nil || slopeRating != nil ||
        courseRatingTimes10 != nil || parValues != nil || handicapValues != nil
    }

    /// Human-readable summary of what was extracted.
    var summary: String {
        var parts: [String] = []
        if let n = courseName        { parts.append("Name: \(n)") }
        if let s = slopeRating       { parts.append("Slope: \(s)") }
        if let r = courseRatingTimes10 {
            parts.append(String(format: "Rating: %.1f", Double(r) / 10.0))
        }
        if parValues != nil          { parts.append("Par (18 holes)") }
        if handicapValues != nil     { parts.append("Handicaps (18 holes)") }
        return parts.isEmpty ? "No scorecard data found." : parts.joined(separator: "\n")
    }
}

enum ScorecardParser {

    // MARK: - Public API

    /// Run Vision OCR on `image` and return extracted scorecard data.
    static func scan(image: UIImage) async throws -> ScorecardScanResult {
        guard let cgImage = image.cgImage else {
            return ScorecardScanResult()
        }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false  // raw OCR — numbers matter more than words

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        let observations = request.results ?? []
        return parse(observations: observations)
    }

    // MARK: - Parsing

    static func parse(observations: [VNRecognizedTextObservation]) -> ScorecardScanResult {
        // Convert observations to (text, boundingBox) pairs, filtering blanks.
        let tokens: [(text: String, box: CGRect)] = observations.compactMap { obs in
            guard let candidate = obs.topCandidates(1).first,
                  !candidate.string.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
            return (candidate.string, obs.boundingBox)
        }

        // Group into rows by Y proximity (Vision coords: 0=bottom, 1=top).
        // We flip Y so row 0 is the top of the image (reading order).
        let rows = groupIntoRows(tokens)

        var result = ScorecardScanResult()

        // Flatten all text tokens for keyword searches.
        let allText = tokens.map { $0.text.lowercased() }.joined(separator: " ")

        result.slopeRating       = extractSlope(from: rows, fullText: allText)
        result.courseRatingTimes10 = extractRating(from: rows, fullText: allText)
        result.courseName        = extractCourseName(from: rows)

        let (par, hcp)           = extractHoleData(from: rows)
        result.parValues         = par
        result.handicapValues    = hcp

        return result
    }

    // MARK: - Row grouping

    /// Groups tokens into horizontal rows using Y-coordinate clustering.
    private static func groupIntoRows(_ tokens: [(text: String, box: CGRect)]) -> [[(text: String, box: CGRect)]] {
        // Flip Vision's Y (bottom=0) → reading-order Y (top=0)
        let flipped = tokens.map { (text: $0.text, box: CGRect(
            x: $0.box.minX,
            y: 1 - $0.box.maxY,  // flip
            width: $0.box.width,
            height: $0.box.height
        )) }

        let sorted = flipped.sorted { $0.box.midY < $1.box.midY }
        let threshold: CGFloat = 0.025  // ~2.5% of image height per row

        var rows: [[(text: String, box: CGRect)]] = []
        for token in sorted {
            if let lastMidY = rows.last?.first?.box.midY,
               abs(token.box.midY - lastMidY) < threshold {
                rows[rows.count - 1].append(token)
            } else {
                rows.append([token])
            }
        }

        // Sort each row left→right
        return rows.map { $0.sorted { $0.box.minX < $1.box.minX } }
    }

    // MARK: - Slope extraction

    private static func extractSlope(from rows: [[(text: String, box: CGRect)]], fullText: String) -> Int? {
        // Strategy 1: keyword "slope" followed or preceded by a 2–3 digit number 55–155
        for row in rows {
            let texts = row.map { $0.text.lowercased() }
            if let slopeIdx = texts.firstIndex(where: { $0.contains("slope") }) {
                // Look in adjacent tokens
                let candidates = Array(row.dropFirst(max(0, slopeIdx - 1)).prefix(5))
                for token in candidates {
                    if let val = parseSlope(token.text) { return val }
                }
            }
        }

        // Strategy 2: scan all tokens for a standalone slope-range number
        // that appears near the word "slope" in the full text
        if fullText.contains("slope") {
            for row in rows {
                for token in row {
                    if let val = parseSlope(token.text) { return val }
                }
            }
        }
        return nil
    }

    private static func parseSlope(_ text: String) -> Int? {
        let digits = text.trimmingCharacters(in: .whitespaces).filter(\.isNumber)
        guard let val = Int(digits), (55...155).contains(val) else { return nil }
        return val
    }

    // MARK: - Course rating extraction

    private static func extractRating(from rows: [[(text: String, box: CGRect)]], fullText: String) -> Int? {
        // Look for a decimal number in range 60.0–80.0 near "rating" keyword
        for row in rows {
            let texts = row.map { $0.text.lowercased() }
            let hasRatingKeyword = texts.contains { $0.contains("rating") }
            let searchRow = hasRatingKeyword ? row : []

            for token in searchRow {
                if let val = parseCourseRating(token.text) { return val }
            }
        }

        // Fallback: find any decimal in rating range across entire text
        if fullText.contains("rating") {
            for row in rows {
                for token in row {
                    if let val = parseCourseRating(token.text) { return val }
                }
            }
        }
        return nil
    }

    private static func parseCourseRating(_ text: String) -> Int? {
        // Match patterns like "72.4", "71.8", etc.
        let pattern = #"(\d{2})\.(\d)"#
        guard let match = text.range(of: pattern, options: .regularExpression) else { return nil }
        let matched = String(text[match])
        guard let val = Double(matched),
              (60.0...80.0).contains(val) else { return nil }
        return Int(val * 10)
    }

    // MARK: - Course name extraction

    private static func extractCourseName(from rows: [[(text: String, box: CGRect)]]) -> String? {
        let skipKeywords = ["slope", "rating", "handicap", "par", "hole", "yards",
                            "yardage", "men", "women", "white", "blue", "red", "gold",
                            "black", "silver", "green", "score", "card", "scorecard",
                            "out", "in", "total", "net", "gross"]

        for row in rows {
            let joined = row.map { $0.text }.joined(separator: " ")
            let lower = joined.lowercased()

            // Skip rows dominated by numbers
            let digits = joined.filter(\.isNumber).count
            let letters = joined.filter(\.isLetter).count
            guard letters > digits else { continue }

            // Skip rows that are clearly metadata
            guard !skipKeywords.contains(where: { lower.contains($0) }) else { continue }

            // Must have at least 3 characters and look like a name
            guard joined.count >= 3 else { continue }

            return joined.trimmingCharacters(in: .whitespaces)
        }
        return nil
    }

    // MARK: - Par and handicap extraction

    /// Returns (parValues, handicapValues) each as 18-element arrays or nil.
    private static func extractHoleData(from rows: [[(text: String, box: CGRect)]]) -> ([Int]?, [Int]?) {
        var allNumericRows: [[Int]] = []

        for row in rows {
            let nums = row.compactMap { Int($0.text.trimmingCharacters(in: .whitespaces)) }
            // Only keep rows with 8+ numbers (scorecards split 9+9 or show all 18)
            guard nums.count >= 8 else { continue }
            allNumericRows.append(nums)
        }

        var parCandidates9:  [Int] = []
        var parCandidates18: [Int] = []
        var hcpCandidates9:  [Int] = []
        var hcpCandidates18: [Int] = []

        for nums in allNumericRows {
            // Try to find a 9-value or 18-value window that fits par or handicap
            let windows9  = windows(of: 9,  in: nums)
            let windows18 = windows(of: 18, in: nums)

            for w in windows18 {
                if isPar(w)      && parCandidates18.isEmpty { parCandidates18 = w }
                if isHandicap(w) && hcpCandidates18.isEmpty { hcpCandidates18 = w }
            }
            for w in windows9 {
                if isPar(w)      && parCandidates9.isEmpty  { parCandidates9 = w }
                if isHandicap(w) && hcpCandidates9.isEmpty  { hcpCandidates9 = w }
            }
        }

        // Prefer 18-hole results; stitch two 9-hole results if needed
        let parResult: [Int]? = {
            if parCandidates18.count == 18 { return parCandidates18 }
            if parCandidates9.count  == 9  { return stitched(front: parCandidates9, allRows: allNumericRows, isPar: true) }
            return nil
        }()

        let hcpResult: [Int]? = {
            if hcpCandidates18.count == 18 { return hcpCandidates18 }
            if hcpCandidates9.count  == 9  { return stitched(front: hcpCandidates9, allRows: allNumericRows, isPar: false) }
            return nil
        }()

        return (parResult, hcpResult)
    }

    /// Checks whether an array looks like a par row (all values 3, 4, or 5).
    private static func isPar(_ nums: [Int]) -> Bool {
        nums.allSatisfy { (3...5).contains($0) }
    }

    /// Checks whether an array looks like a handicap/SI row
    /// (all values 1–18, each unique — but relax uniqueness for 9-hole windows).
    private static func isHandicap(_ nums: [Int]) -> Bool {
        guard nums.allSatisfy({ (1...18).contains($0) }) else { return false }
        // For 18-value arrays require uniqueness
        if nums.count == 18 { return Set(nums).count == 18 }
        // For 9-value allow some overlap (front/back SI can share values on some scorecards)
        return Set(nums).count >= 7
    }

    /// Sliding window helper.
    private static func windows(of size: Int, in nums: [Int]) -> [[Int]] {
        guard nums.count >= size else { return [] }
        return (0...(nums.count - size)).map { Array(nums[$0..<($0 + size)]) }
    }

    /// Given a 9-hole front candidate, find the matching back-9 in remaining rows.
    private static func stitched(front: [Int], allRows: [[Int]], isPar: Bool) -> [Int]? {
        for nums in allRows {
            for back in windows(of: 9, in: nums) {
                guard back != front else { continue }
                let combined = front + back
                if isPar {
                    if Self.isPar(combined) { return combined }
                } else {
                    if isHandicap(combined) { return combined }
                }
            }
        }
        return nil
    }
}
