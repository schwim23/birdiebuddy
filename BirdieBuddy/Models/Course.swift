import Foundation

/// Holds static course data until a real course database is added.
struct Course {
    /// Default stroke index: hole number → difficulty rank (1 = hardest, 18 = easiest).
    /// A player with handicap H receives a stroke on every hole whose SI ≤ H.
    static let defaultStrokeIndex: [Int: Int] = [
        1: 13, 2: 5,  3: 1,  4: 11, 5: 3,  6: 7,  7: 15, 8: 17, 9: 9,
        10: 14, 11: 6, 12: 2, 13: 12, 14: 4, 15: 8, 16: 16, 17: 18, 18: 10
    ]

    /// Returns true if the player receives at least one handicap stroke on the given hole (stroke play).
    static func receivesStroke(_ player: Player, on hole: Int) -> Bool {
        guard player.handicap > 0, let si = defaultStrokeIndex[hole] else { return false }
        return si <= player.handicap
    }

    /// Strokes the player receives vs opponent on a hole in match play.
    /// Only the higher-handicapper receives strokes based on the differential.
    static func matchPlayStrokes(for player: Player, against opponent: Player, on hole: Int) -> Int {
        let diff = player.handicap - opponent.handicap
        guard diff > 0, let si = defaultStrokeIndex[hole] else { return 0 }
        var strokes = 0
        if si <= diff      { strokes += 1 }
        if si <= diff - 18 { strokes += 1 }   // second stroke when diff > 18
        return strokes
    }
}
