import Foundation

enum ScoreParser {
    // MARK: - Static lookup tables (allocated once)

    private static let wordToInt: [String: Int] = [
        "one": 1, "two": 2, "three": 3, "four": 4, "five": 5,
        "six": 6, "seven": 7, "eight": 8, "nine": 9
    ]

    /// Phonetic misrecognitions → canonical golf term.
    private static let phoneticAliases: [String: String] = [
        "bougie": "bogey", "boogie": "bogey", "boggy": "bogey",
        "bogy": "bogey",  "bogi":  "bogey",
        "bertie": "birdie", "birdy": "birdie", "burdie": "birdie",
        "birdee": "birdie", "burdy": "birdie",
        "double bougie": "double bogey", "double boogie": "double bogey",
        "double boggy":  "double bogey",
        "eagled": "eagle",
    ]

    /// Golf terms sorted longest-first so "double bogey" matches before "bogey".
    /// Par-relative offsets stored; absolute score calculated at call time.
    private static let golfTermOffsets: [(String, Int)] = [
        ("hole in one", -99),   // special: always 1
        ("ace",         -99),   // special: always 1
        ("triple bogey", +3),
        ("double bogey", +2),
        ("triple",       +3),
        ("double",       +2),
        ("eagle",        -2),
        ("birdie",       -1),
        ("bogey",        +1),
        ("par",           0),
    ]

    /// Vocabulary hints for the speech recogniser (improves on-device accuracy).
    static let contextualStrings: [String] = [
        "ace", "eagle", "birdie", "par", "bogey",
        "double bogey", "triple bogey", "double", "triple",
        "hole in one",
        "one", "two", "three", "four", "five",
        "six", "seven", "eight", "nine",
    ]

    // MARK: - Parse

    /// Parses spoken or typed text into a stroke count (1–9).
    static func parse(_ text: String, par: Int) -> Int? {
        let lowered = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // Direct digit
        if let n = Int(lowered), (1...9).contains(n) { return n }

        // Number words — check each token
        for word in lowered.components(separatedBy: .whitespaces) {
            if let n = wordToInt[word] { return n }
            if let n = Int(word), (1...9).contains(n) { return n }
        }

        // Normalize phonetic misrecognitions
        var normalized = lowered
        for (alias, canonical) in phoneticAliases {
            if normalized.contains(alias) {
                normalized = normalized.replacingOccurrences(of: alias, with: canonical)
            }
        }

        // Golf terms (longest match first)
        for (term, offset) in golfTermOffsets {
            guard normalized.contains(term) else { continue }
            let score = offset == -99 ? 1 : par + offset
            if (1...9).contains(score) { return score }
        }

        return nil
    }
}
