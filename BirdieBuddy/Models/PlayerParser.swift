import Foundation

enum PlayerParser {
    struct ParsedPlayer {
        let name: String
        let handicap: Int?
    }

    /// Parses a spoken or typed string into one or more players.
    /// Handles comma- and "and"-separated lists, number words, digits, and "scratch".
    /// Example: "add joe chanley he is a 12 handicap, mike s who is a 14, dan who is a 8 and josh who is a 9"
    static func parse(_ text: String) -> [ParsedPlayer] {
        var cleaned = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("add ") { cleaned = String(cleaned.dropFirst(4)) }

        // Split on commas first, then try " and " within each segment
        let segments = cleaned
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }

        var results: [ParsedPlayer] = []
        for segment in segments where !segment.isEmpty {
            if let player = parseOne(segment) {
                results.append(player)
            } else {
                // Segment didn't parse as a single player — try splitting on " and "
                let parts = segment
                    .components(separatedBy: " and ")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                for part in parts where !part.isEmpty {
                    if let player = parseOne(part) {
                        results.append(player)
                    }
                }
            }
        }
        return results
    }

    // MARK: - Private

    private static func parseOne(_ segment: String) -> ParsedPlayer? {
        var s = segment.trimmingCharacters(in: .whitespaces)
        guard !s.isEmpty else { return nil }
        if s.hasPrefix("add ") { s = String(s.dropFirst(4)) }

        // Normalize number words to digits
        s = normalizeNumberWords(s)

        // "scratch" shorthand for 0 handicap
        if s.hasSuffix(" scratch") {
            let name = String(s.dropLast(8)).trimmingCharacters(in: .whitespaces)
            return name.isEmpty ? nil : ParsedPlayer(name: capitalized(name), handicap: 0)
        }

        // Patterns tried in order — all capture (name, handicap)
        let patterns: [String] = [
            // "NAME [he/she/who] [is/are/has] [a] NUMBER [handicap]"
            #"^(.+?)\s+(?:(?:he|she|who|they)\s+)?(?:is|are|has|have)\s+a?\s*(\d+)(?:\s+handicap)?$"#,
            // "NAME handicap [of] NUMBER"
            #"^(.+?)\s+(?:handicap(?:\s+of)?\s*|hcp\s*)(\d+)$"#,
            // "NAME at NUMBER" / "NAME a NUMBER"
            #"^(.+?)\s+(?:at|a)\s+(\d+)$"#,
            // "NAME NUMBER" bare number at end
            #"^(.+?)\s+(\d+)$"#,
        ]

        for pattern in patterns {
            if let result = match(pattern: pattern, in: s) {
                return ParsedPlayer(name: capitalized(result.name), handicap: result.handicap)
            }
        }

        // No handicap found — just a name (filter obvious filler)
        let fillers: Set<String> = ["a", "the", "and", "or", "who", "is", "he", "she", "they", "add"]
        if !fillers.contains(s) && s.count > 1 {
            return ParsedPlayer(name: capitalized(s), handicap: nil)
        }
        return nil
    }

    private static func match(pattern: String, in text: String) -> (name: String, handicap: Int)? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let m = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              m.numberOfRanges >= 3,
              let nameRange = Range(m.range(at: 1), in: text),
              let hcpRange = Range(m.range(at: 2), in: text)
        else { return nil }

        let name = String(text[nameRange]).trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty, let handicap = Int(text[hcpRange]), (0...54).contains(handicap) else { return nil }
        return (name, handicap)
    }

    /// Replaces spoken number words with digit strings so patterns can match.
    private static func normalizeNumberWords(_ text: String) -> String {
        let map: [(String, String)] = [
            ("zero", "0"), ("one", "1"), ("two", "2"), ("three", "3"), ("four", "4"),
            ("five", "5"), ("six", "6"), ("seven", "7"), ("eight", "8"), ("nine", "9"),
            ("ten", "10"), ("eleven", "11"), ("twelve", "12"), ("thirteen", "13"),
            ("fourteen", "14"), ("fifteen", "15"), ("sixteen", "16"), ("seventeen", "17"),
            ("eighteen", "18"), ("nineteen", "19"), ("twenty", "20"),
            ("thirty", "30"), ("forty", "40"), ("fifty", "50"),
        ]
        var result = text
        for (word, digit) in map {
            result = result.replacingOccurrences(of: "\\b\(word)\\b", with: digit, options: .regularExpression)
        }
        return result
    }

    private static func capitalized(_ s: String) -> String {
        s.split(separator: " ").map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined(separator: " ")
    }
}
