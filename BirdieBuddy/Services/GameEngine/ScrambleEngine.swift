
import Foundation

final class ScrambleEngine: GameEngineProtocol {
    let format: GameFormat = .scramble

    func calculateStandings(round: GolfRound, game: Game) -> [PlayerStanding] {
        var standings: [PlayerStanding] = []
        for team in game.teams {
            var holeScores: [Int: Int] = [:]
            for s in round.scores where team.playerIds.contains(s.playerId) {
                let cur = holeScores[s.holeNumber] ?? s.netScore
                holeScores[s.holeNumber] = min(cur, s.netScore)
            }
            let total = holeScores.values.reduce(0, +)
            let names = round.players.filter { team.playerIds.contains($0.playerId) }.map(\.displayName).joined(separator: " & ")
            standings.append(PlayerStanding(id: team.id, playerName: names, playerId: team.playerIds.first ?? UUID(), teamId: team.id, teamName: team.name, points: Double(total), matchStatus: "Score: \(total)", position: 0))
        }
        standings.sort { $0.points < $1.points }
        for i in standings.indices { standings[i].position = i + 1 }
        return standings
    }

    func holeResult(round: GolfRound, game: Game, holeNumber: Int) -> HoleResult? { nil }
}
