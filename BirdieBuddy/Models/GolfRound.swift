
import Foundation
import SwiftData

@Model
final class GolfRound {
    var id: UUID
    var date: Date
    var holeCount: Int
    var status: String

    var course: Course?

    @Relationship(deleteRule: .cascade, inverse: \RoundPlayer.round)
    var players: [RoundPlayer] = []

    @Relationship(deleteRule: .cascade, inverse: \HoleScore.round)
    var scores: [HoleScore] = []

    @Relationship(deleteRule: .cascade, inverse: \Game.round)
    var games: [Game] = []

    @Relationship(deleteRule: .cascade, inverse: \ShotVideo.round)
    var videos: [ShotVideo] = []

    @Relationship(inverse: \Trip.rounds)
    var trip: Trip?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        holeCount: Int = 18,
        status: String = RoundStatus.setup.rawValue
    ) {
        self.id = id
        self.date = date
        self.holeCount = holeCount
        self.status = status
    }

    var roundStatus: RoundStatus {
        get { RoundStatus(rawValue: status) ?? .setup }
        set { status = newValue.rawValue }
    }

    func scoresForHole(_ holeNumber: Int) -> [HoleScore] {
        scores.filter { $0.holeNumber == holeNumber }
    }

    func scoresForPlayer(_ playerId: UUID) -> [HoleScore] {
        scores.filter { $0.playerId == playerId }.sorted { $0.holeNumber < $1.holeNumber }
    }

    func totalGrossScore(for playerId: UUID) -> Int {
        scoresForPlayer(playerId).reduce(0) { $0 + $1.grossScore }
    }

    func totalNetScore(for playerId: UUID) -> Int {
        scoresForPlayer(playerId).reduce(0) { $0 + $1.netScore }
    }

    var completedHoles: Int {
        guard !players.isEmpty else { return 0 }
        let playerCount = players.count
        var completed = 0
        for hole in 1...holeCount {
            let holeScores = scoresForHole(hole)
            if holeScores.count == playerCount && holeScores.allSatisfy({ $0.grossScore > 0 }) {
                completed += 1
            }
        }
        return completed
    }
}

enum RoundStatus: String, Codable {
    case setup
    case active
    case completed
    case cancelled
}
