import Foundation

enum PlayerParser {
    struct ParsedPlayer {
        let name: String
        let handicap: Int?
    }

    // MARK: - Pre-compiled regex cache

    /// Patterns tried in order; all capture (name group 1, handicap group 2).
    private static let handicapPatterns: [NSRegularExpression] = [
        // "NAME [he/she/who] [is/are/has] [a] NUMBER [handicap]"
        try! NSRegularExpression(
            pattern: #"^(.+?)\s+(?:(?:he|she|who|they)\s+)?(?:is|are|has|have)\s+a?\s*(\d+)(?:\s+handicap)?$"#),
        // "NAME handicap [of] NUMBER"
        try! NSRegularExpression(
            pattern: #"^(.+?)\s+(?:handicap(?:\s+of)?\s*|hcp\s*)(\d+)$"#),
        // "NAME at NUMBER" / "NAME a NUMBER"
        try! NSRegularExpression(
            pattern: #"^(.+?)\s+(?:at|a)\s+(\d+)$"#),
        // "NAME NUMBER" — bare number at end
        try! NSRegularExpression(
            pattern: #"^(.+?)\s+(\d+)$"#),
    ]

    /// Pre-compiled number-word → digit substitution pairs.
    private static let numberWordPatterns: [(NSRegularExpression, String)] = {
        let map: [(String, String)] = [
            ("zero", "0"), ("one", "1"), ("two", "2"), ("three", "3"), ("four", "4"),
            ("five", "5"), ("six", "6"), ("seven", "7"), ("eight", "8"), ("nine", "9"),
            ("ten", "10"), ("eleven", "11"), ("twelve", "12"), ("thirteen", "13"),
            ("fourteen", "14"), ("fifteen", "15"), ("sixteen", "16"), ("seventeen", "17"),
            ("eighteen", "18"), ("nineteen", "19"), ("twenty", "20"),
            ("thirty", "30"), ("forty", "40"), ("fifty", "50"),
        ]
        return map.compactMap { word, digit in
            guard let re = try? NSRegularExpression(pattern: "\\b\(word)\\b") else { return nil }
            return (re, digit)
        }
    }()

    // MARK: - Parse

    /// Parses a spoken or typed string into one or more players.
    static func parse(_ text: String) -> [ParsedPlayer] {
        var cleaned = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("add ") { cleaned = String(cleaned.dropFirst(4)) }

        let segments = cleaned
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }

        var results: [ParsedPlayer] = []
        for segment in segments where !segment.isEmpty {
            if let player = parseOne(segment) {
                results.append(player)
            } else {
                for part in segment.components(separatedBy: " and ").map({ $0.trimmingCharacters(in: .whitespaces) }) where !part.isEmpty {
                    if let player = parseOne(part) { results.append(player) }
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

        s = normalizeNumberWords(s)

        if s.hasSuffix(" scratch") {
            let name = String(s.dropLast(8)).trimmingCharacters(in: .whitespaces)
            return name.isEmpty ? nil : ParsedPlayer(name: capitalized(name), handicap: 0)
        }

        for regex in handicapPatterns {
            if let result = match(regex: regex, in: s) {
                return ParsedPlayer(name: capitalized(result.name), handicap: result.handicap)
            }
        }

        let fillers: Set<String> = ["a", "the", "and", "or", "who", "is", "he", "she", "they", "add"]
        if !fillers.contains(s) && s.count > 1 {
            return ParsedPlayer(name: capitalized(s), handicap: nil)
        }
        return nil
    }

    private static func match(regex: NSRegularExpression, in text: String) -> (name: String, handicap: Int)? {
        let range = NSRange(text.startIndex..., in: text)
        guard let m = regex.firstMatch(in: text, range: range),
              m.numberOfRanges >= 3,
              let nameRange = Range(m.range(at: 1), in: text),
              let hcpRange  = Range(m.range(at: 2), in: text)
        else { return nil }

        let name = String(text[nameRange]).trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty,
              let handicap = Int(text[hcpRange]),
              (0...54).contains(handicap)
        else { return nil }
        return (name, handicap)
    }

    private static func normalizeNumberWords(_ text: String) -> String {
        var result = text
        let nsResult = result as NSString
        var mutable = NSMutableString(string: nsResult)
        for (regex, digit) in numberWordPatterns {
            regex.replaceMatches(in: mutable, range: NSRange(location: 0, length: mutable.length), withTemplate: digit)
        }
        return mutable as String
    }

    private static func capitalized(_ s: String) -> String {
        s.split(separator: " ").map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined(separator: " ")
    }
}
