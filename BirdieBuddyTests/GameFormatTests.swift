import Testing
import Foundation
@testable import BirdieBuddy

// MARK: - Shared helpers

private func makePlayers(_ handicaps: [Int]) -> [Player] {
    handicaps.map { Player(name: "P\(handicaps.firstIndex(of: $0) ?? 0)", handicap: $0) }
}

private func makeState(format: GameFormat, handicaps: [Int], teams: [UUID: Int] = [:]) -> AppState {
    let state = AppState()
    let players = handicaps.enumerated().map { Player(name: "P\($0.offset)", handicap: $0.element) }
    let t = teams.isEmpty ? [:] as [UUID: Int] : teams
    state.startRound(with: players, format: format, teams: t)
    return state
}

// Records strokes for players on a hole (indexed by players array position)
private func record(_ state: AppState, hole: Int, strokes: [Int]) {
    for (i, s) in strokes.enumerated() {
        state.recordScore(s, forHole: hole, player: state.players[i])
    }
}

// MARK: - Group Net Score

@Suite("Group Net Strokes")
struct GroupNetTests {

    @Test("equal handicaps — no strokes given")
    func equalHandicaps() {
        let state = makeState(format: .fiveThreeOne, handicaps: [10, 10, 10, 10])
        for p in state.players {
            #expect(state.groupNetStrokes(for: p, on: 1) == 0)
        }
    }

    @Test("handicap differential allocates strokes by SI")
    func strokesByDiff() {
        let state = makeState(format: .fiveThreeOne, handicaps: [0, 4, 8, 12])
        let p3 = state.players[3] // handicap 12, diff = 12 vs minHcp 0
        let p0 = state.players[0] // handicap 0, diff = 0
        let si1Hole = state.roundStrokeIndex.min(by: { $0.value < $1.value })!.key
        #expect(state.groupNetStrokes(for: p0, on: si1Hole) == 0)
        #expect(state.groupNetStrokes(for: p3, on: si1Hole) >= 1)
    }
}

// MARK: - Best Ball

@Suite("Best Ball")
struct BestBallTests {

    private func bbState(handicaps: [Int] = [0,0,0,0]) -> AppState {
        let state = makeState(format: .bestBall, handicaps: handicaps)
        // Default teams: P0+P2 = Team A, P1+P3 = Team B
        return state
    }

    @Test("Team A wins hole when their best net is lower")
    func teamAWinsHole() {
        let state = bbState()
        // P0=3, P2=3 → best 3.  P1=5, P3=5 → best 5.  Team A wins.
        record(state, hole: 1, strokes: [3, 5, 3, 5])
        let result = state.bestBallHoleResult(for: 1)
        #expect(result == .teamWins(teamIndex: 0))
    }

    @Test("Team B wins hole")
    func teamBWinsHole() {
        let state = bbState()
        record(state, hole: 1, strokes: [5, 3, 5, 3])
        #expect(state.bestBallHoleResult(for: 1) == .teamWins(teamIndex: 1))
    }

    @Test("halved when best nets equal")
    func halved() {
        let state = bbState()
        record(state, hole: 1, strokes: [4, 4, 5, 5])
        #expect(state.bestBallHoleResult(for: 1) == .halved)
    }

    @Test("nil result when not fully scored")
    func nilIfMissingScore() {
        let state = bbState()
        // Only P0 and P1 scored
        state.recordScore(4, forHole: 1, player: state.players[0])
        state.recordScore(4, forHole: 1, player: state.players[1])
        #expect(state.bestBallHoleResult(for: 1) == nil)
    }

    @Test("holesUp tracks running match")
    func holesUp() {
        let state = bbState()
        record(state, hole: 1, strokes: [3, 5, 3, 5])  // Team A wins
        record(state, hole: 2, strokes: [5, 3, 5, 3])  // Team B wins
        #expect(state.bestBallHolesUp == 0)
        record(state, hole: 3, strokes: [3, 5, 3, 5])  // Team A wins again
        #expect(state.bestBallHolesUp == 1)
    }

    @Test("status text All Square")
    func allSquareText() {
        let state = bbState()
        #expect(state.bestBallStatusText == "All Square")
    }

    @Test("status text Team A 2 UP")
    func teamALeadText() {
        let state = bbState()
        record(state, hole: 1, strokes: [3, 5, 3, 5])
        record(state, hole: 2, strokes: [3, 5, 3, 5])
        #expect(state.bestBallStatusText.contains("Team A"))
        #expect(state.bestBallStatusText.contains("2 UP"))
    }

    @Test("net scores applied via handicap differential")
    func netScoreFlips() {
        // P0=0 hcp, P2=0 hcp vs P1=18 hcp, P3=18 hcp
        // On SI 1 hole, P1 and P3 each get 1 stroke
        // P0 gross 4 = net 4; P1 gross 5 = net 4 → halved
        let state = makeState(format: .bestBall, handicaps: [0, 18, 0, 18])
        let si1Hole = state.roundStrokeIndex.min(by: { $0.value < $1.value })!.key
        state.recordScore(4, forHole: si1Hole, player: state.players[0])
        state.recordScore(5, forHole: si1Hole, player: state.players[1])
        state.recordScore(4, forHole: si1Hole, player: state.players[2])
        state.recordScore(5, forHole: si1Hole, player: state.players[3])
        #expect(state.bestBallHoleResult(for: si1Hole) == .halved)
    }
}

// MARK: - Alternate Shot

@Suite("Alternate Shot")
struct AlternateShotTests {

    private func altState(handicaps: [Int] = [0,0,0,0]) -> AppState {
        // Default teams: P0+P2 = Team A, P1+P3 = Team B (matches AppState.defaultTeamIndex)
        makeState(format: .alternateShot, handicaps: handicaps)
    }

    @Test("Team A wins hole when its captain's net is lower")
    func teamAWinsHole() {
        let s = altState()
        // Captains are P0 (Team A) and P1 (Team B)
        s.recordScore(4, forHole: 1, player: s.players[0])
        s.recordScore(5, forHole: 1, player: s.players[1])
        #expect(s.alternateShotHoleResult(for: 1) == .teamWins(teamIndex: 0))
    }

    @Test("Team B wins hole")
    func teamBWinsHole() {
        let s = altState()
        s.recordScore(5, forHole: 1, player: s.players[0])
        s.recordScore(4, forHole: 1, player: s.players[1])
        #expect(s.alternateShotHoleResult(for: 1) == .teamWins(teamIndex: 1))
    }

    @Test("halved when captain nets equal")
    func halved() {
        let s = altState()
        s.recordScore(4, forHole: 1, player: s.players[0])
        s.recordScore(4, forHole: 1, player: s.players[1])
        #expect(s.alternateShotHoleResult(for: 1) == .halved)
    }

    @Test("nil result when one team hasn't scored")
    func nilIfMissingScore() {
        let s = altState()
        s.recordScore(4, forHole: 1, player: s.players[0])
        #expect(s.alternateShotHoleResult(for: 1) == nil)
    }

    @Test("scoring one teammate mirrors to the other")
    func scoreMirrorsAcrossTeammates() {
        let s = altState()
        s.recordScore(5, forHole: 1, player: s.players[0])
        // P2 is P0's teammate (Team A) and should now show 5
        #expect(s.score(for: s.players[2], hole: 1) == 5)
        // P1 (Team B) is unaffected
        #expect(s.score(for: s.players[1], hole: 1) == nil)
    }

    @Test("team handicap is rounded average")
    func teamHandicap() {
        // Team A = P0(8) + P2(11) avg 9.5 → 10. Team B = P1(2) + P3(5) avg 3.5 → 4
        let s = altState(handicaps: [8, 2, 11, 5])
        #expect(s.teamHandicap(0) == 10)
        #expect(s.teamHandicap(1) == 4)
    }

    @Test("higher-handicap team gets stroke on SI 1")
    func strokeAllocation() {
        // Team A combined handicap 6 vs Team B 0, diff 6 → A gets a stroke on SI 1–6
        let s = altState(handicaps: [6, 0, 6, 0])
        let si1Hole = s.roundStrokeIndex.min(by: { $0.value < $1.value })!.key
        #expect(s.alternateShotTeamReceivesStroke(team: 0, on: si1Hole))
        #expect(!s.alternateShotTeamReceivesStroke(team: 1, on: si1Hole))
    }

    @Test("net score gives weaker team the hole on SI 1")
    func netScoreWinsHole() {
        let s = altState(handicaps: [6, 0, 6, 0])
        let si1Hole = s.roundStrokeIndex.min(by: { $0.value < $1.value })!.key
        // Team A captain shoots 5, Team B captain shoots 4. Net: A 4, B 4 → halved
        s.recordScore(5, forHole: si1Hole, player: s.players[0])
        s.recordScore(4, forHole: si1Hole, player: s.players[1])
        #expect(s.alternateShotHoleResult(for: si1Hole) == .halved)
    }

    @Test("status text shows All Square initially")
    func allSquareText() {
        #expect(altState().alternateShotStatusText == "All Square")
    }

    @Test("status text reflects 2 UP lead")
    func twoUpText() {
        let s = altState()
        s.recordScore(3, forHole: 1, player: s.players[0])
        s.recordScore(5, forHole: 1, player: s.players[1])
        s.recordScore(3, forHole: 2, player: s.players[0])
        s.recordScore(5, forHole: 2, player: s.players[1])
        #expect(s.alternateShotStatusText.contains("Team A"))
        #expect(s.alternateShotStatusText.contains("2 UP"))
    }
}

// MARK: - 5-3-1

@Suite("5-3-1")
struct FiveThreeOneTests {

    private func state() -> AppState { makeState(format: .fiveThreeOne, handicaps: [0,0,0,0]) }

    @Test("clear finish: 5-3-1-0 distribution")
    func clearFinish() {
        let s = state()
        record(s, hole: 1, strokes: [3, 4, 5, 6])
        let pts = s.fiveThreeOneHolePoints(for: 1)
        #expect(pts[s.players[0].id] == 5)
        #expect(pts[s.players[1].id] == 3)
        #expect(pts[s.players[2].id] == 1)
        #expect(pts[s.players[3].id] == 0)
    }

    @Test("two-way tie for 1st splits 5+3")
    func tieForFirst() {
        let s = state()
        record(s, hole: 1, strokes: [3, 3, 5, 6])
        let pts = s.fiveThreeOneHolePoints(for: 1)
        #expect(pts[s.players[0].id] == 4.0)
        #expect(pts[s.players[1].id] == 4.0)
        #expect(pts[s.players[2].id] == 1.0)
        #expect(pts[s.players[3].id] == 0.0)
    }

    @Test("four-way tie splits all 9 points evenly")
    func fourWayTie() {
        let s = state()
        record(s, hole: 1, strokes: [4, 4, 4, 4])
        let pts = s.fiveThreeOneHolePoints(for: 1)
        let total = pts.values.reduce(0.0, +)
        #expect(abs(total - 9.0) < 0.001)
        for p in s.players {
            #expect(abs((pts[p.id] ?? 0) - 2.25) < 0.001)
        }
    }

    @Test("nil hole returns empty dict")
    func unplayedHole() {
        let s = state()
        #expect(s.fiveThreeOneHolePoints(for: 1).isEmpty)
    }

    @Test("running totals accumulate correctly")
    func runningTotals() {
        let s = state()
        record(s, hole: 1, strokes: [3, 4, 5, 6])  // P0=5, P1=3, P2=1, P3=0
        record(s, hole: 2, strokes: [6, 5, 4, 3])  // P0=0, P1=1, P2=3, P3=5
        #expect(s.fiveThreeOnePoints(for: s.players[0]) == 5)
        #expect(s.fiveThreeOnePoints(for: s.players[3]) == 5)
        #expect(s.fiveThreeOnePoints(for: s.players[1]) == 4)
        #expect(s.fiveThreeOnePoints(for: s.players[2]) == 4)
    }

    @Test("standings are sorted descending")
    func standingsSorted() {
        let s = state()
        record(s, hole: 1, strokes: [3, 4, 5, 6])
        let standings = s.fiveThreeOneStandings
        for i in 0..<standings.count - 1 {
            #expect(standings[i].points >= standings[i + 1].points)
        }
    }

    @Test("points formatted without trailing .0 for whole numbers")
    func formattedWholeNumber() {
        let s = state()
        #expect(s.fiveThreeOnePointsFormatted(5.0) == "5")
        #expect(s.fiveThreeOnePointsFormatted(4.5) == "4.5")
    }
}

// MARK: - Wolf

@Suite("Wolf")
struct WolfTests {

    private func state() -> AppState { makeState(format: .wolf, handicaps: [0,0,0,0]) }

    @Test("wolf rotates by hole number")
    func wolfRotation() {
        let s = state()
        #expect(s.wolfPlayer(for: 1)?.id == s.players[0].id)
        #expect(s.wolfPlayer(for: 2)?.id == s.players[1].id)
        #expect(s.wolfPlayer(for: 3)?.id == s.players[2].id)
        #expect(s.wolfPlayer(for: 4)?.id == s.players[3].id)
        #expect(s.wolfPlayer(for: 5)?.id == s.players[0].id)
    }

    @Test("no points before decision")
    func noPointsBeforeDecision() {
        let s = state()
        record(s, hole: 1, strokes: [3, 4, 5, 6])
        #expect(s.wolfHolePoints(for: 1).isEmpty)
    }

    @Test("lone wolf wins: wolf 4, others 0")
    func loneWolfWins() {
        let s = state()
        s.setWolfDecision(for: 1, partnerID: nil)
        record(s, hole: 1, strokes: [3, 4, 5, 6])  // P0 wolf, best score
        let pts = s.wolfHolePoints(for: 1)
        #expect(pts[s.players[0].id] == 4)
        #expect(pts[s.players[1].id] == 0)
        #expect(pts[s.players[2].id] == 0)
        #expect(pts[s.players[3].id] == 0)
    }

    @Test("lone wolf loses: others 2 each")
    func loneWolfLoses() {
        let s = state()
        s.setWolfDecision(for: 1, partnerID: nil)
        record(s, hole: 1, strokes: [6, 4, 4, 4])  // P0 wolf, worst score
        let pts = s.wolfHolePoints(for: 1)
        #expect(pts[s.players[0].id] == 0)
        #expect(pts[s.players[1].id] == 2)
        #expect(pts[s.players[2].id] == 2)
        #expect(pts[s.players[3].id] == 2)
    }

    @Test("wolf + partner win: wolf 2, partner 1, others 0")
    func wolfPartnerWin() {
        let s = state()
        let partner = s.players[1]
        s.setWolfDecision(for: 1, partnerID: partner.id)
        // P0(wolf)+P1(partner) best is 3, others best is 5
        record(s, hole: 1, strokes: [3, 4, 5, 6])
        let pts = s.wolfHolePoints(for: 1)
        #expect(pts[s.players[0].id] == 2)
        #expect(pts[s.players[1].id] == 1)
        #expect(pts[s.players[2].id] == 0)
        #expect(pts[s.players[3].id] == 0)
    }

    @Test("wolf + partner lose: opponents 2 each, wolf+partner 0")
    func wolfPartnerLose() {
        let s = state()
        let partner = s.players[1]
        s.setWolfDecision(for: 1, partnerID: partner.id)
        record(s, hole: 1, strokes: [5, 6, 3, 4])  // others win
        let pts = s.wolfHolePoints(for: 1)
        #expect(pts[s.players[0].id] == 0)
        #expect(pts[s.players[1].id] == 0)
        #expect(pts[s.players[2].id] == 2)
        #expect(pts[s.players[3].id] == 2)
    }

    @Test("halved: all get 1")
    func halved() {
        let s = state()
        let partner = s.players[1]
        s.setWolfDecision(for: 1, partnerID: partner.id)
        record(s, hole: 1, strokes: [4, 5, 4, 5])  // best wolf team = 4, best other = 4
        let pts = s.wolfHolePoints(for: 1)
        for p in s.players {
            #expect(pts[p.id] == 1)
        }
    }

    @Test("cumulative wolf points")
    func cumulativePoints() {
        let s = state()
        // Hole 1: P0 wolf, goes lone, wins
        s.setWolfDecision(for: 1, partnerID: nil)
        record(s, hole: 1, strokes: [3, 4, 5, 6])
        // Hole 2: P1 wolf, picks P2 as partner, wins
        s.setWolfDecision(for: 2, partnerID: s.players[2].id)
        record(s, hole: 2, strokes: [5, 3, 4, 6])  // wolf=3, partner=4 → best 3; others best 5
        #expect(s.wolfPoints(for: s.players[0]) == 4)  // lone wolf win
        #expect(s.wolfPoints(for: s.players[1]) == 2)  // wolf win
        #expect(s.wolfPoints(for: s.players[2]) == 1)  // partner win
    }

    @Test("wolf standings sorted descending")
    func standingsSorted() {
        let s = state()
        s.setWolfDecision(for: 1, partnerID: nil)
        record(s, hole: 1, strokes: [3, 4, 5, 6])
        let standings = s.wolfStandings
        for i in 0..<standings.count - 1 {
            #expect(standings[i].points >= standings[i + 1].points)
        }
    }
}

// MARK: - Format compatibility

@Suite("Format Compatibility")
struct FormatCompatTests {

    @Test("stroke play compatible with 1–4 players")
    func strokePlay() {
        for n in 1...4 { #expect(GameFormat.strokePlay.isCompatible(with: n)) }
    }

    @Test("match play only for 2")
    func matchPlay() {
        #expect(!GameFormat.matchPlay.isCompatible(with: 1))
        #expect(GameFormat.matchPlay.isCompatible(with: 2))
        #expect(!GameFormat.matchPlay.isCompatible(with: 3))
    }

    @Test("4-player formats require exactly 4")
    func fourPlayerFormats() {
        for format in [GameFormat.bestBall, .wolf, .fiveThreeOne, .alternateShot] {
            #expect(!format.isCompatible(with: 3))
            #expect(format.isCompatible(with: 4))
        }
    }

    @Test("alternate shot is a team format")
    func alternateShotIsTeamFormat() {
        #expect(GameFormat.alternateShot.isTeamFormat)
    }
}
