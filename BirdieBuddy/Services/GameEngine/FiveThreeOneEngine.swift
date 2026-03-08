
import Foundation

final class FiveThreeOneEngine: GameEngineProtocol {
    let format: GameFormat = .fiveThreeOne

    func calculateStandings(round: GolfRound, game: Game) -> [PlayerStanding] {
        let players = round.players
        var pts: [UUID: Double] = Dictionary(uniqueKeysWithValues: players.map { ($0.playerId, 0.0) })
        let maxH = round.scores.map(\.holeNumber).max() ?? 0
        guard maxH > 0 else {
            return players.enumerated().map { i, p in PlayerStanding(id: p.id, playerName: p.displayName, playerId: p.playerId, points: 0, matchStatus: "0 pts", position: i+1) }
        }
        for h in 1...maxH {
            let hs = round.scoresForHole(h)
            guard hs.count == 4 else { continue }
            let sorted = hs.sorted { $0.netScore < $1.netScore }
            let vals: [Double] = [5,3,1,0]
            for (i, s) in sorted.enumerated() { pts[s.playerId, default: 0] += vals[i] }
        }
        var result = players.map { p in PlayerStanding(id: p.id, playerName: p.displayName, playerId: p.playerId, points: pts[p.playerId] ?? 0, matchStatus: "\(Int(pts[p.playerId] ?? 0)) pts", position: 0) }
        result.sort { $0.points > $1.points }
        for i in result.indices { result[i].position = i + 1 }
        return result
    }

    func holeResult(round: GolfRound, game: Game, holeNumber: Int) -> HoleResult? {
        let hs = round.scoresForHole(holeNumber)
        guard hs.count == 4 else { return nil }
        let best = hs.min(by: { $0.netScore < $1.netScore })
        let name = round.players.first { $0.playerId == best?.playerId }?.displayName
        return HoleResult(holeNumber: holeNumber, winnerId: best?.playerId, winnerName: name, isHalved: false, details: "\(name ?? "?") gets 5 pts")
    }
}
