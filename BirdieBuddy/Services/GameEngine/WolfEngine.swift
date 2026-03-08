
import Foundation

final class WolfEngine: GameEngineProtocol {
    let format: GameFormat = .wolf

    func calculateStandings(round: GolfRound, game: Game) -> [PlayerStanding] {
        let players = round.players
        guard players.count == 4 else { return [] }
        let rotation = game.config.wolfRotationOrder.isEmpty ? players.map(\.playerId) : game.config.wolfRotationOrder
        var pts: [UUID: Double] = Dictionary(uniqueKeysWithValues: players.map { ($0.playerId, 0.0) })
        let maxH = round.scores.map(\.holeNumber).max() ?? 0
        guard maxH > 0 else {
            return players.enumerated().map { i, p in PlayerStanding(id: p.id, playerName: p.displayName, playerId: p.playerId, points: 0, matchStatus: "0 pts", position: i+1) }
        }
        for h in 1...maxH {
            let hs = round.scoresForHole(h)
            guard hs.count == 4 else { continue }
            let wolfId = rotation[(h-1) % 4]
            guard let wolfNet = hs.first(where: { $0.playerId == wolfId })?.netScore else { continue }
            let others = hs.filter { $0.playerId != wolfId }.sorted { $0.netScore < $1.netScore }
            let allNets = hs.map(\.netScore).sorted()
            if wolfNet <= allNets[0] && wolfNet < allNets[1] {
                pts[wolfId, default: 0] += 4 // Lone wolf
            } else {
                let partnerId = others[0].playerId
                let bestTeam = min(wolfNet, others[0].netScore)
                let opps = others.filter { $0.playerId != partnerId }
                let bestOpp = opps.map(\.netScore).min() ?? 99
                if bestTeam < bestOpp {
                    pts[wolfId, default: 0] += 2; pts[partnerId, default: 0] += 2
                } else if bestTeam > bestOpp {
                    for o in opps { pts[o.playerId, default: 0] += 2 }
                }
            }
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
        return HoleResult(holeNumber: holeNumber, winnerId: best?.playerId, winnerName: name, isHalved: false, details: "\(name ?? "?") wins hole")
    }
}
