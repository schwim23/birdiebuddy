import Foundation
import SwiftData

/// A single entry in the encoded scores array.
struct ScoreEntry: Codable {
    let playerName: String
    let hole: Int
    let strokes: Int
}

@Model
final class RoundRecord {
    var id: UUID
    var date: Date
    var playerNames: [String]
    /// JSON-encoded [ScoreEntry] — avoids SwiftData relationship complexity.
    var scoresData: Data

    init(date: Date, players: [Player], scores: [UUID: [Int: Int]]) {
        self.id = UUID()
        self.date = date
        self.playerNames = players.map { $0.name }

        var entries: [ScoreEntry] = []
        for player in players {
            for (hole, strokes) in scores[player.id] ?? [:] {
                entries.append(ScoreEntry(playerName: player.name, hole: hole, strokes: strokes))
            }
        }
        self.scoresData = (try? JSONEncoder().encode(entries)) ?? Data()
    }

    /// Decoded score entries.
    var scoreEntries: [ScoreEntry] {
        (try? JSONDecoder().decode([ScoreEntry].self, from: scoresData)) ?? []
    }

    /// Total strokes for a given player name.
    func totalScore(for playerName: String) -> Int {
        scoreEntries.filter { $0.playerName == playerName }.reduce(0) { $0 + $1.strokes }
    }
}
