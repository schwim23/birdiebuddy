import Foundation

/// Parses a single spoken utterance into scores for multiple players.
///
/// Example input: "joe got a bogey, mike got a par, sam doubled and jon birdied that hole"
/// Returns: [joe→5, mike→4, sam→6, jon→3] for par 4
enum MultiScoreParser {

    struct ParsedScore {
        let playerName: String   // matched player's original-casing name
        let strokes: Int
    }

    // MARK: - Public

    /// Parses `text` and returns one `ParsedScore` per matched player.
    /// Unrecognised player names and unparseable score fragments are silently ignored.
    static func parse(_ text: String, players: [Player], par: Int) -> [ParsedScore] {
        let lower = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !lower.isEmpty, !players.isEmpty else { return [] }

        // "everyone [verb] [score]" / "all [score]" — assign same score to all players
        for prefix in ["everyone", "all"] {
            if lower.hasPrefix(prefix) {
                let remainder = String(lower.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
                let scoreText = stripFillerVerb(remainder)
                if let strokes = ScoreParser.parse(scoreText, par: par) {
                    return players.map { ParsedScore(playerName: $0.name, strokes: strokes) }
                }
            }
        }

        // Split on commas, then on connector phrases within each comma-segment
        let connectors = [" and ", " then ", " also "]
        var segments: [String] = []
        for commaPart in lower.components(separatedBy: ",") {
            var parts = [commaPart]
            for connector in connectors {
                parts = parts.flatMap { $0.components(separatedBy: connector) }
            }
            segments.append(contentsOf: parts)
        }

        var results: [ParsedScore] = []
        for segment in segments {
            let trimmed = segment.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            guard let ps = parseSegment(trimmed, players: players, par: par) else { continue }
            // One result per player — first match wins
            guard !results.contains(where: { $0.playerName == ps.playerName }) else { continue }
            results.append(ps)
        }
        return results
    }

    // MARK: - Private

    /// Attempts to extract one (player, score) pair from a segment.
    /// Tries a two-word name first, then a one-word name.
    private static func parseSegment(_ segment: String, players: [Player], par: Int) -> ParsedScore? {
        let tokens = segment.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard tokens.count >= 2 else { return nil }

        for nameTokenCount in [2, 1] {
            guard tokens.count > nameTokenCount else { continue }
            let namePart = tokens.prefix(nameTokenCount).joined(separator: " ")
            guard let player = matchPlayer(namePart, in: players) else { continue }
            let scoreText = tokens.dropFirst(nameTokenCount).joined(separator: " ")
            if let strokes = ScoreParser.parse(scoreText, par: par) {
                return ParsedScore(playerName: player.name, strokes: strokes)
            }
        }
        return nil
    }

    /// Case-insensitive match against player first name or full name.
    private static func matchPlayer(_ token: String, in players: [Player]) -> Player? {
        players.first { player in
            let firstName = player.name.components(separatedBy: " ").first?.lowercased() ?? ""
            return firstName == token || player.name.lowercased() == token
        }
    }

    /// Strips leading filler verbs so ScoreParser can handle the remainder.
    /// e.g. "made par" → "par", "got a bogey" → "bogey"
    private static func stripFillerVerb(_ text: String) -> String {
        var result = text
        for filler in ["made ", "had ", "got ", "shot ", "scored ", "a ", "an "] {
            if result.hasPrefix(filler) {
                result = String(result.dropFirst(filler.count))
            }
        }
        return result
    }
}
