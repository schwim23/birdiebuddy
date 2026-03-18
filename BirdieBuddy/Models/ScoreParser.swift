import Foundation

enum ScoreParser {
    /// Parses spoken or typed text into a stroke count (1–9).
    /// Accepts digit strings ("5"), number words ("five"), and
    /// common golf terms relative to par (birdie, bogey, eagle, etc.).
    /// Phonetic aliases handle common speech-recognizer mismatches.
    static func parse(_ text: String, par: Int) -> Int? {
        let lowered = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // Direct digit
        if let n = Int(lowered), (1...9).contains(n) { return n }

        // Number words — check each token
        let wordToInt: [String: Int] = [
            "one": 1, "two": 2, "three": 3, "four": 4, "five": 5,
            "six": 6, "seven": 7, "eight": 8, "nine": 9
        ]
        for word in lowered.components(separatedBy: .whitespaces) {
            if let n = wordToInt[word] { return n }
            if let n = Int(word), (1...9).contains(n) { return n }
        }

        // Normalize phonetic misrecognitions before golf term matching.
        // Speech recognizers commonly mishear golf terms — map them to canonical forms.
        let phoneticAliases: [String: String] = [
            // bogey variants
            "bougie": "bogey", "boogie": "bogey", "boggy": "bogey",
            "bogy": "bogey", "bogi": "bogey",
            // birdie variants
            "bertie": "birdie", "birdy": "birdie", "burdie": "birdie",
            "birdee": "birdie", "burdy": "birdie",
            // double bogey compound variants
            "double bougie": "double bogey", "double boogie": "double bogey",
            "double boggy": "double bogey",
            // eagle variants (less common but just in case)
            "eagled": "eagle",
        ]
        var normalized = lowered
        for (alias, canonical) in phoneticAliases {
            normalized = normalized.replacingOccurrences(of: alias, with: canonical)
        }

        // Golf terms relative to par (longest match first to catch "double bogey" before "bogey")
        let golfTerms: [(String, Int)] = [
            ("hole in one", 1), ("ace", 1),
            ("double bogey", par + 2), ("triple bogey", par + 3),
            ("double", par + 2), ("triple", par + 3),
            ("eagle", par - 2),
            ("birdie", par - 1),
            ("bogey", par + 1),
            ("par", par),
        ]
        for (term, score) in golfTerms {
            if normalized.contains(term), (1...9).contains(score) { return score }
        }

        return nil
    }
}
