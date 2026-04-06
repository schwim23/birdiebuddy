import Foundation
import Observation

@Observable
final class AppState {
    var players: [Player] = []
    var currentHole: Int = 1
    var isRoundActive: Bool = false
    var gameFormat: GameFormat = .strokePlay
    /// scores[playerID][holeNumber] = strokes
    var scores: [UUID: [Int: Int]] = [:]

    /// Course configuration snapshot taken at round start.
    var roundPar: [Int: Int] = Course.defaultPar
    var roundStrokeIndex: [Int: Int] = Course.defaultStrokeIndex

    var isRoundFinished: Bool { currentHole > 18 }

    // MARK: - Course helpers

    func par(for hole: Int) -> Int { roundPar[hole] ?? 4 }
    func strokeIndex(for hole: Int) -> Int { roundStrokeIndex[hole] ?? hole }

    // MARK: - Setup

    func startRound(with players: [Player], format: GameFormat = .strokePlay, course: CourseSetup? = nil) {
        self.players = players
        self.gameFormat = format
        currentHole = 1
        isRoundActive = true
        scores = [:]
        roundPar = course?.parDict ?? Course.defaultPar
        roundStrokeIndex = course?.strokeIndexDict ?? Course.defaultStrokeIndex
    }

    func startRound(with players: [Player], format: GameFormat = .strokePlay, courseRecord: CourseRecord, tee: String) {
        self.players = players
        self.gameFormat = format
        currentHole = 1
        isRoundActive = true
        scores = [:]
        roundPar = courseRecord.parDict
        roundStrokeIndex = courseRecord.strokeIndexDict
    }

    // MARK: - Scoring

    func score(for player: Player, hole: Int) -> Int? {
        scores[player.id]?[hole]
    }

    func totalScore(for player: Player) -> Int {
        scores[player.id]?.values.reduce(0, +) ?? 0
    }

    func recordScore(_ strokes: Int, forHole hole: Int, player: Player) {
        guard (1...18).contains(hole) else { return }
        scores[player.id, default: [:]][hole] = strokes

        // Advance the leading hole once every player has scored this hole.
        if hole >= currentHole && players.allSatisfy({ scores[$0.id]?[hole] != nil }) {
            currentHole = hole + 1
        }

        // Match play: end round early if match is decided.
        if gameFormat == .matchPlay, matchIsDecided, !isRoundFinished {
            currentHole = 19
        }
    }

    // MARK: - Match Play

    /// Net score for a player on a hole (gross minus match play strokes received).
    func matchNetScore(for player: Player, hole: Int) -> Int? {
        guard players.count == 2,
              let gross = score(for: player, hole: hole),
              let opponent = players.first(where: { $0.id != player.id }) else { return nil }
        let strokes = matchPlayStrokes(for: player, against: opponent, on: hole)
        return gross - strokes
    }

    /// Who won a specific hole in match play, or nil if not yet fully scored.
    func matchHoleResult(for hole: Int) -> HoleResult? {
        guard players.count == 2 else { return nil }
        let p1 = players[0], p2 = players[1]
        guard let n1 = matchNetScore(for: p1, hole: hole),
              let n2 = matchNetScore(for: p2, hole: hole) else { return nil }
        if n1 < n2 { return .playerWins(p1) }
        if n2 < n1 { return .playerWins(p2) }
        return .halved
    }

    /// Running match status: positive = players[0] leads, negative = players[1] leads.
    var matchHolesUp: Int {
        guard players.count == 2 else { return 0 }
        return (1...18).reduce(0) { acc, hole in
            switch matchHoleResult(for: hole) {
            case .playerWins(let p) where p.id == players[0].id: return acc + 1
            case .playerWins:                                     return acc - 1
            default:                                              return acc
            }
        }
    }

    /// Number of holes where both players have recorded a score.
    var matchHolesPlayed: Int {
        guard players.count == 2 else { return 0 }
        return (1...18).filter { hole in players.allSatisfy { score(for: $0, hole: hole) != nil } }.count
    }

    var matchIsDecided: Bool {
        abs(matchHolesUp) > (18 - matchHolesPlayed)
    }

    /// Human-readable running match status (e.g. "Mike 2 UP", "All Square", "Dormie 1").
    var matchStatusText: String {
        guard players.count == 2, gameFormat == .matchPlay else { return "" }
        let up = matchHolesUp
        let remaining = 18 - matchHolesPlayed
        if up == 0 { return "All Square" }
        let leader = up > 0 ? players[0] : players[1]
        let lead = abs(up)
        if lead > remaining { return "\(leader.name) wins \(lead)&\(remaining)" }
        if lead == remaining { return "Dormie \(lead)" }
        return "\(leader.name) \(lead) UP"
    }

    /// True when the player receives a stroke on this hole for the current format.
    func receivesStroke(_ player: Player, on hole: Int) -> Bool {
        if gameFormat == .matchPlay, players.count == 2,
           let opponent = players.first(where: { $0.id != player.id }) {
            return matchPlayStrokes(for: player, against: opponent, on: hole) > 0
        }
        // Stroke play: use round's stroke index
        guard player.handicap > 0, let si = roundStrokeIndex[hole] else { return false }
        return si <= player.handicap
    }

    // MARK: - Private match play stroke calculation (uses roundStrokeIndex)

    private func matchPlayStrokes(for player: Player, against opponent: Player, on hole: Int) -> Int {
        let diff = player.handicap - opponent.handicap
        guard diff > 0, let si = roundStrokeIndex[hole] else { return 0 }
        var strokes = 0
        if si <= diff      { strokes += 1 }
        if si <= diff - 18 { strokes += 1 }
        return strokes
    }
}
