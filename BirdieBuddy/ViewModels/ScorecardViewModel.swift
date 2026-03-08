
import SwiftUI
import SwiftData

@MainActor
@Observable
final class ScorecardViewModel {
    var round: GolfRound
    var currentHole: Int = 1
    var showVoiceInput: Bool = false
    var showMatchStatus: Bool = false
    var showVideoRecord: Bool = false

    init(round: GolfRound) { self.round = round }

    var currentHoleInfo: Hole? { round.course?.sortedHoles.first { $0.number == currentHole } }
    var currentHolePar: Int { currentHoleInfo?.par ?? 4 }
    var maxHole: Int { round.holeCount }

    func nextHole() { if currentHole < maxHole { currentHole += 1 } }
    func previousHole() { if currentHole > 1 { currentHole -= 1 } }
    func goToHole(_ h: Int) { if (1...maxHole).contains(h) { currentHole = h } }

    func scoreForPlayer(_ pid: UUID) -> HoleScore? {
        round.scores.first { $0.playerId == pid && $0.holeNumber == currentHole }
    }

    func setScore(playerId: UUID, grossScore: Int, modelContext: ModelContext) {
        let player = round.players.first { $0.playerId == playerId }
        let holeInfo = currentHoleInfo
        let strokes = player?.strokesOnHole(
            holeNumber: currentHole,
            holeHandicapRating: holeInfo?.handicapRating ?? currentHole,
            totalHoles: maxHole
        ) ?? 0
        let net = grossScore - strokes

        if let existing = scoreForPlayer(playerId) {
            existing.grossScore = grossScore
            existing.netScore = net
            existing.strokesReceived = strokes
        } else {
            let s = HoleScore(playerId: playerId, holeNumber: currentHole, grossScore: grossScore, netScore: net, strokesReceived: strokes)
            s.round = round
            round.scores.append(s)
            modelContext.insert(s)
        }
        try? modelContext.save()
    }

    func applyVoiceIntent(_ intent: VoiceIntent, modelContext: ModelContext) {
        guard let score = intent.score, let pid = intent.playerId else { return }
        setScore(playerId: pid, grossScore: score, modelContext: modelContext)
    }

    func allHolesScored(for h: Int) -> Bool {
        let hs = round.scoresForHole(h)
        return hs.count == round.players.count && hs.allSatisfy { $0.grossScore > 0 }
    }

    func completeRound(modelContext: ModelContext) {
        round.roundStatus = .completed
        try? modelContext.save()
    }

    func scoreType(gross: Int, par: Int) -> ScoreType { ScoreType.from(gross: gross, par: par) }

    func gameStandings(for game: Game) -> [PlayerStanding] {
        GameEngineFactory.engine(for: game.format).calculateStandings(round: round, game: game)
    }
}
