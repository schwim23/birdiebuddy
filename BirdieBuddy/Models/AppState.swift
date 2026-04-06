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

    /// Best Ball / Alternate Shot: playerID → team index (0 or 1).
    var teamAssignments: [UUID: Int] = [:]

    /// Wolf: hole number → wolf state for that hole.
    var wolfHoleStates: [Int: WolfHoleState] = [:]

    var isRoundFinished: Bool { currentHole > 18 }

    // MARK: - Course helpers

    func par(for hole: Int) -> Int { roundPar[hole] ?? 4 }
    func strokeIndex(for hole: Int) -> Int { roundStrokeIndex[hole] ?? hole }

    // MARK: - Setup

    func startRound(with players: [Player], format: GameFormat = .strokePlay,
                    course: CourseSetup? = nil, teams: [UUID: Int] = [:]) {
        self.players = players
        self.gameFormat = format
        currentHole = 1
        isRoundActive = true
        scores = [:]
        roundPar = course?.parDict ?? Course.defaultPar
        roundStrokeIndex = course?.strokeIndexDict ?? Course.defaultStrokeIndex
        teamAssignments = teams.isEmpty ? defaultTeams(for: players) : teams
        wolfHoleStates = [:]
    }

    func startRound(with players: [Player], format: GameFormat = .strokePlay,
                    courseRecord: CourseRecord, tee: String, teams: [UUID: Int] = [:]) {
        self.players = players
        self.gameFormat = format
        currentHole = 1
        isRoundActive = true
        scores = [:]
        roundPar = courseRecord.parDict
        roundStrokeIndex = courseRecord.strokeIndexDict
        teamAssignments = teams.isEmpty ? defaultTeams(for: players) : teams
        wolfHoleStates = [:]
    }

    private func defaultTeams(for players: [Player]) -> [UUID: Int] {
        guard players.count == 4 else { return [:] }
        // Default pairing: 0+2 = Team A, 1+3 = Team B
        return [players[0].id: 0, players[1].id: 1, players[2].id: 0, players[3].id: 1]
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

        // End round early when match is decided.
        if gameFormat == .matchPlay, matchIsDecided, !isRoundFinished {
            currentHole = 19
        }
        if gameFormat == .bestBall, bestBallIsDecided, !isRoundFinished {
            currentHole = 19
        }
    }

    // MARK: - True whether a player receives a handicap stroke on a hole

    func receivesStroke(_ player: Player, on hole: Int) -> Bool {
        switch gameFormat {
        case .matchPlay:
            guard players.count == 2,
                  let opp = players.first(where: { $0.id != player.id }) else { return false }
            return matchPlayStrokes(for: player, against: opp, on: hole) > 0
        case .bestBall, .wolf, .fiveThreeOne:
            return groupNetStrokes(for: player, on: hole) > 0
        case .strokePlay:
            guard player.handicap > 0, let si = roundStrokeIndex[hole] else { return false }
            return si <= player.handicap
        }
    }

    // MARK: - General status text (format-aware)

    var statusText: String {
        switch gameFormat {
        case .strokePlay:  return ""
        case .matchPlay:   return matchStatusText
        case .bestBall:    return bestBallStatusText
        case .wolf:        return wolfStandingsText
        case .fiveThreeOne: return fiveThreeOneStandingsText
        }
    }

    // MARK: - Match Play

    func matchNetScore(for player: Player, hole: Int) -> Int? {
        guard players.count == 2,
              let gross = score(for: player, hole: hole),
              let opp = players.first(where: { $0.id != player.id }) else { return nil }
        return gross - matchPlayStrokes(for: player, against: opp, on: hole)
    }

    func matchHoleResult(for hole: Int) -> HoleResult? {
        guard players.count == 2 else { return nil }
        let p1 = players[0], p2 = players[1]
        guard let n1 = matchNetScore(for: p1, hole: hole),
              let n2 = matchNetScore(for: p2, hole: hole) else { return nil }
        if n1 < n2 { return .playerWins(p1) }
        if n2 < n1 { return .playerWins(p2) }
        return .halved
    }

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

    var matchHolesPlayed: Int {
        guard players.count == 2 else { return 0 }
        return (1...18).filter { hole in players.allSatisfy { score(for: $0, hole: hole) != nil } }.count
    }

    var matchIsDecided: Bool { abs(matchHolesUp) > (18 - matchHolesPlayed) }

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

    private func matchPlayStrokes(for player: Player, against opp: Player, on hole: Int) -> Int {
        let diff = player.handicap - opp.handicap
        guard diff > 0, let si = roundStrokeIndex[hole] else { return 0 }
        var s = 0
        if si <= diff      { s += 1 }
        if si <= diff - 18 { s += 1 }
        return s
    }

    // MARK: - Group Net (Best Ball / Wolf / 5-3-1)
    //   Each player's net = gross − strokes allocated relative to the lowest-handicap player.

    func groupNetScore(for player: Player, hole: Int) -> Int? {
        guard let gross = score(for: player, hole: hole) else { return nil }
        return gross - groupNetStrokes(for: player, on: hole)
    }

    func groupNetStrokes(for player: Player, on hole: Int) -> Int {
        let minHcp = players.map(\.handicap).min() ?? 0
        let diff = player.handicap - minHcp
        guard diff > 0, let si = roundStrokeIndex[hole] else { return 0 }
        var s = 0
        if si <= diff      { s += 1 }
        if si <= diff - 18 { s += 1 }
        return s
    }

    // MARK: - Best Ball

    func teamPlayers(team: Int) -> [Player] {
        players.filter { teamAssignments[$0.id] == team }
    }

    func teamIndex(for player: Player) -> Int { teamAssignments[player.id] ?? 0 }
    func teamName(_ index: Int) -> String { index == 0 ? "Team A" : "Team B" }

    func bestBallHoleResult(for hole: Int) -> HoleResult? {
        guard gameFormat == .bestBall else { return nil }
        let t0 = teamPlayers(team: 0), t1 = teamPlayers(team: 1)
        guard !t0.isEmpty, !t1.isEmpty else { return nil }
        let nets0 = t0.compactMap { groupNetScore(for: $0, hole: hole) }
        let nets1 = t1.compactMap { groupNetScore(for: $0, hole: hole) }
        // Only report result once all players on both teams have scored
        guard nets0.count == t0.count, nets1.count == t1.count else { return nil }
        guard let b0 = nets0.min(), let b1 = nets1.min() else { return nil }
        if b0 < b1 { return .teamWins(teamIndex: 0) }
        if b1 < b0 { return .teamWins(teamIndex: 1) }
        return .halved
    }

    var bestBallHolesUp: Int {
        (1...18).reduce(0) { acc, hole in
            switch bestBallHoleResult(for: hole) {
            case .teamWins(let t) where t == 0: return acc + 1
            case .teamWins:                      return acc - 1
            default:                             return acc
            }
        }
    }

    var bestBallHolesPlayed: Int {
        (1...18).filter { hole in
            teamPlayers(team: 0).allSatisfy { score(for: $0, hole: hole) != nil } &&
            teamPlayers(team: 1).allSatisfy { score(for: $0, hole: hole) != nil }
        }.count
    }

    var bestBallIsDecided: Bool { abs(bestBallHolesUp) > (18 - bestBallHolesPlayed) }

    var bestBallStatusText: String {
        guard gameFormat == .bestBall else { return "" }
        let up = bestBallHolesUp
        let remaining = 18 - bestBallHolesPlayed
        if up == 0 { return "All Square" }
        let leadTeam = up > 0 ? 0 : 1
        let lead = abs(up)
        if lead > remaining { return "Team \(teamName(leadTeam)) wins \(lead)&\(remaining)" }
        if lead == remaining { return "Dormie \(lead)" }
        return "Team \(teamName(leadTeam)) \(lead) UP"
    }

    // MARK: - 5-3-1

    func fiveThreeOneHolePoints(for hole: Int) -> [UUID: Double] {
        guard gameFormat == .fiveThreeOne, players.count == 4 else { return [:] }
        guard players.allSatisfy({ scores[$0.id]?[hole] != nil }) else { return [:] }
        let base = [5.0, 3.0, 1.0, 0.0]
        let nets = players.map { (id: $0.id, net: groupNetScore(for: $0, hole: hole) ?? 9999) }
            .sorted { $0.net < $1.net }
        var result = [UUID: Double]()
        var i = 0
        while i < nets.count {
            var j = i
            while j < nets.count && nets[j].net == nets[i].net { j += 1 }
            let split = (i..<j).reduce(0.0) { $0 + base[$1] } / Double(j - i)
            for k in i..<j { result[nets[k].id] = split }
            i = j
        }
        return result
    }

    func fiveThreeOnePoints(for player: Player) -> Double {
        (1...18).reduce(0.0) { $0 + (fiveThreeOneHolePoints(for: $1)[player.id] ?? 0) }
    }

    var fiveThreeOneStandings: [(player: Player, points: Double)] {
        players.map { (player: $0, points: fiveThreeOnePoints(for: $0)) }
            .sorted { $0.points > $1.points }
    }

    private var fiveThreeOneStandingsText: String {
        guard !players.isEmpty else { return "" }
        return fiveThreeOneStandings
            .map { "\($0.player.name): \(fiveThreeOnePointsFormatted($0.points))" }
            .joined(separator: "  ")
    }

    func fiveThreeOnePointsFormatted(_ pts: Double) -> String {
        pts.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(pts))" : String(format: "%.1f", pts)
    }

    // MARK: - Wolf

    func wolfPlayer(for hole: Int) -> Player? {
        guard players.count >= 4 else { return nil }
        return players[(hole - 1) % players.count]
    }

    func setWolfDecision(for hole: Int, partnerID: UUID?) {
        guard let wolf = wolfPlayer(for: hole) else { return }
        wolfHoleStates[hole] = WolfHoleState(
            wolfPlayerID: wolf.id,
            partnerPlayerID: partnerID,
            isLoneWolf: partnerID == nil,
            isDecided: true
        )
    }

    func wolfHolePoints(for hole: Int) -> [UUID: Int] {
        guard gameFormat == .wolf, players.count == 4 else { return [:] }
        guard let state = wolfHoleStates[hole], state.isDecided else { return [:] }
        guard players.allSatisfy({ scores[$0.id]?[hole] != nil }) else { return [:] }
        guard let wolf = players.first(where: { $0.id == state.wolfPlayerID }) else { return [:] }
        let wolfNet = groupNetScore(for: wolf, hole: hole)!

        var pts = [UUID: Int]()
        if state.isLoneWolf {
            let others = players.filter { $0.id != state.wolfPlayerID }
            let otherNets = others.map { groupNetScore(for: $0, hole: hole)! }
            if otherNets.allSatisfy({ wolfNet < $0 }) {
                pts[wolf.id] = 4; others.forEach { pts[$0.id] = 0 }
            } else if otherNets.allSatisfy({ $0 < wolfNet }) {
                pts[wolf.id] = 0; others.forEach { pts[$0.id] = 2 }
            } else {
                players.forEach { pts[$0.id] = 1 }
            }
        } else if let partnerID = state.partnerPlayerID,
                  let partner = players.first(where: { $0.id == partnerID }) {
            let partnerNet = groupNetScore(for: partner, hole: hole)!
            let bestWolf = min(wolfNet, partnerNet)
            let others = players.filter { $0.id != wolf.id && $0.id != partner.id }
            let bestOther = others.map { groupNetScore(for: $0, hole: hole)! }.min()!
            if bestWolf < bestOther {
                pts[wolf.id] = 2; pts[partner.id] = 1; others.forEach { pts[$0.id] = 0 }
            } else if bestOther < bestWolf {
                pts[wolf.id] = 0; pts[partner.id] = 0; others.forEach { pts[$0.id] = 2 }
            } else {
                players.forEach { pts[$0.id] = 1 }
            }
        }
        return pts
    }

    func wolfPoints(for player: Player) -> Int {
        (1...18).reduce(0) { $0 + (wolfHolePoints(for: $1)[player.id] ?? 0) }
    }

    var wolfStandings: [(player: Player, points: Int)] {
        players.map { (player: $0, points: wolfPoints(for: $0)) }
            .sorted { $0.points > $1.points }
    }

    private var wolfStandingsText: String {
        guard !players.isEmpty else { return "" }
        return wolfStandings
            .map { "\($0.player.name): \($0.points)" }
            .joined(separator: "  ")
    }
}
