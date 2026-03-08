
import Foundation

final class FourBallEngine: GameEngineProtocol {
    let format: GameFormat = .fourBall

    func calculateStandings(round: GolfRound, game: Game) -> [PlayerStanding] {
        var standings: [PlayerStanding] = []
        for team in game.teams {
            var total = 0
            for h in 1...round.holeCount {
                let ts = round.scores.filter { team.playerIds.contains($0.playerId) && $0.holeNumber == h }
                if let best = ts.min(by: { $0.netScore < $1.netScore }) { total += best.netScore }
            }
            let names = round.players.filter { team.playerIds.contains($0.playerId) }.map(\.displayName).joined(separator: " & ")
            standings.append(PlayerStanding(id: team.id, playerName: names, playerId: team.playerIds.first ?? UUID(), teamId: team.id, teamName: team.name, points: Double(total), matchStatus: "Net: \(total)", position: 0))
        }
        standings.sort { $0.points < $1.points }
        for i in standings.indices { standings[i].position = i + 1 }
        return standings
    }

    func holeResult(round: GolfRound, game: Game, holeNumber: Int) -> HoleResult? { nil }
}
