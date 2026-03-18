import Foundation
import Observation

@Observable
final class AppState {
    var players: [Player] = []
    var currentHole: Int = 1
    var currentPlayerIndex: Int = 0
    var isRoundActive: Bool = false
    /// scores[playerID][holeNumber] = strokes
    var scores: [UUID: [Int: Int]] = [:]

    var currentPlayer: Player? {
        guard players.indices.contains(currentPlayerIndex) else { return nil }
        return players[currentPlayerIndex]
    }

    var isRoundFinished: Bool { currentHole > 18 }

    func totalScore(for player: Player) -> Int {
        scores[player.id]?.values.reduce(0, +) ?? 0
    }

    func score(for player: Player, hole: Int) -> Int? {
        scores[player.id]?[hole]
    }

    func startRound(with players: [Player]) {
        self.players = players
        currentHole = 1
        currentPlayerIndex = 0
        isRoundActive = true
        scores = [:]
    }

    func recordScore(_ strokes: Int, forHole hole: Int, player: Player) {
        guard (1...18).contains(hole) else { return }
        scores[player.id, default: [:]][hole] = strokes

        // Advance to next player; when all players on this hole are done, advance the hole
        if currentPlayerIndex < players.count - 1 {
            currentPlayerIndex += 1
        } else {
            currentPlayerIndex = 0
            if hole >= currentHole {
                currentHole = hole + 1
            }
        }
    }
}
