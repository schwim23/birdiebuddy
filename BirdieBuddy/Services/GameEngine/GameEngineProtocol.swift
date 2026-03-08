
import Foundation

protocol GameEngineProtocol {
    var format: GameFormat { get }
    func calculateStandings(round: GolfRound, game: Game) -> [PlayerStanding]
    func holeResult(round: GolfRound, game: Game, holeNumber: Int) -> HoleResult?
}

struct PlayerStanding: Identifiable {
    var id: UUID
    var playerName: String
    var playerId: UUID
    var teamId: UUID?
    var teamName: String?
    var points: Double
    var matchStatus: String
    var position: Int
}

struct HoleResult {
    var holeNumber: Int
    var winnerId: UUID?
    var winnerName: String?
    var winningTeamId: UUID?
    var isHalved: Bool
    var details: String
}

struct HandicapCalculator {
    static func courseHandicap(handicapIndex: Double, slopeRating: Int, courseRating: Double, par: Int) -> Int {
        let ch = (handicapIndex * Double(slopeRating) / 113.0) + (courseRating - Double(par))
        return Int(ch.rounded())
    }

    static func strokesPerHole(courseHandicap: Int, holeHandicapRatings: [Int]) -> [Int: Int] {
        var strokeMap: [Int: Int] = [:]
        let total = holeHandicapRatings.count
        guard total > 0 else { return strokeMap }
        let sorted = holeHandicapRatings.enumerated().sorted { $0.element < $1.element }
        let abs = abs(courseHandicap)
        let sign = courseHandicap >= 0 ? 1 : -1
        let full = abs / total
        let rem = abs % total
        for entry in sorted { strokeMap[entry.offset + 1] = full * sign }
        for i in 0..<rem { strokeMap[sorted[i].offset + 1, default: 0] += sign }
        return strokeMap
    }
}
