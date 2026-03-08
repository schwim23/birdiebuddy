
import Foundation

final class NassauEngine: GameEngineProtocol {
    let format: GameFormat = .nassau

    func calculateStandings(round: GolfRound, game: Game) -> [PlayerStanding] {
        let players = round.players
        guard players.count >= 2 else { return [] }
        var standings: [PlayerStanding] = []
        for player in players {
            let scores = round.scoresForPlayer(player.playerId)
            let f9 = scores.filter { $0.holeNumber <= 9 }.reduce(0) { $0 + $1.netScore }
            let b9 = scores.filter { $0.holeNumber > 9 }.reduce(0) { $0 + $1.netScore }
            let total = f9 + b9
            standings.append(PlayerStanding(id: player.id, playerName: player.displayName, playerId: player.playerId, points: Double(total), matchStatus: "F9:\(f9) B9:\(b9) T:\(total)", position: 0))
        }
        standings.sort { $0.points < $1.points }
        for i in standings.indices { standings[i].position = i + 1 }
        return standings
    }

    func holeResult(round: GolfRound, game: Game, holeNumber: Int) -> HoleResult? {
        let hs = round.scoresForHole(holeNumber)
        guard hs.count >= 2 else { return nil }
        let sorted = hs.sorted { $0.netScore < $1.netScore }
        if sorted[0].netScore == sorted[1].netScore {
            return HoleResult(holeNumber: holeNumber, isHalved: true, details: "Halved")
        }
        let w = round.players.first { $0.playerId == sorted[0].playerId }
        return HoleResult(holeNumber: holeNumber, winnerId: sorted[0].playerId, winnerName: w?.displayName, isHalved: false, details: "\(w?.displayName ?? "?") wins net \(sorted[0].netScore)")
    }
}
