import Foundation
import Observation

@Observable
final class AppState {
    var players: [Player] = []
    var currentHole: Int = 1
    var isRoundActive: Bool = false
    /// scores[playerID][holeNumber] = strokes
    var scores: [UUID: [Int: Int]] = [:]

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
        isRoundActive = true
        scores = [:]
    }

    func recordScore(_ strokes: Int, forHole hole: Int, player: Player) {
        guard (1...18).contains(hole) else { return }
        scores[player.id, default: [:]][hole] = strokes

        // Advance the leading hole once every player has scored this hole.
        if hole >= currentHole && players.allSatisfy({ scores[$0.id]?[hole] != nil }) {
            currentHole = hole + 1
        }
    }
}
