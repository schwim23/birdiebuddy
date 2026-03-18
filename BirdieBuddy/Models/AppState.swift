import Foundation
import Observation

@Observable
final class AppState {
    var currentHole: Int = 1
    var isRoundActive: Bool = false
    var scores: [Int: Int] = [:]

    var isRoundFinished: Bool {
        currentHole > 18
    }

    var totalScore: Int {
        scores.values.reduce(0, +)
    }

    func startRound() {
        currentHole = 1
        isRoundActive = true
        scores = [:]
    }

    func recordScore(_ strokes: Int, forHole hole: Int) {
        guard (1...18).contains(hole) else { return }
        scores[hole] = strokes
        // Only advance the leading hole pointer when scoring a new hole, not re-edits
        if hole >= currentHole {
            currentHole = hole + 1
        }
    }
}
