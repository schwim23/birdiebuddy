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
    /// JSON-encoded [Int: Int] par per hole. nil for pre-D06 records; falls back to Course.defaultPar.
    var parData: Data?

    init(date: Date, players: [Player], scores: [UUID: [Int: Int]], roundPar: [Int: Int] = [:]) {
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
        self.parData = roundPar.isEmpty ? nil : try? JSONEncoder().encode(roundPar)
    }

    /// Decoded score entries.
    var scoreEntries: [ScoreEntry] {
        (try? JSONDecoder().decode([ScoreEntry].self, from: scoresData)) ?? []
    }

    /// Par per hole for this round. Falls back to all-4s default for pre-D06 records.
    var roundPar: [Int: Int] {
        guard let data = parData,
              let decoded = try? JSONDecoder().decode([Int: Int].self, from: data)
        else { return Course.defaultPar }
        return decoded
    }

    /// Total strokes for a given player name.
    func totalScore(for playerName: String) -> Int {
        scoreEntries.filter { $0.playerName == playerName }.reduce(0) { $0 + $1.strokes }
    }

    /// Total par for holes played by a given player.
    func totalPar(for playerName: String) -> Int {
        let holes = scoreEntries.filter { $0.playerName == playerName }.map { $0.hole }
        return holes.reduce(0) { $0 + (roundPar[$1] ?? 4) }
    }
}
