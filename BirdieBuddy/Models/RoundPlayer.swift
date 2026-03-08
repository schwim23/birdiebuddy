
import Foundation
import SwiftData

@Model
final class RoundPlayer {
    var id: UUID
    var displayName: String
    var courseHandicap: Int
    var teamId: UUID?
    var playerId: UUID
    var strokesReceivedData: Data?

    var round: GolfRound?
    var userProfile: UserProfile?

    init(
        id: UUID = UUID(),
        displayName: String = "",
        courseHandicap: Int = 0,
        teamId: UUID? = nil,
        playerId: UUID = UUID()
    ) {
        self.id = id
        self.displayName = displayName
        self.courseHandicap = courseHandicap
        self.teamId = teamId
        self.playerId = playerId
    }

    var strokesReceived: [Int: Int] {
        get {
            guard let data = strokesReceivedData else { return [:] }
            return (try? JSONDecoder().decode([Int: Int].self, from: data)) ?? [:]
        }
        set {
            strokesReceivedData = try? JSONEncoder().encode(newValue)
        }
    }

    func strokesOnHole(holeNumber: Int, holeHandicapRating: Int, totalHoles: Int) -> Int {
        if let cached = strokesReceived[holeNumber] {
            return cached
        }
        guard totalHoles > 0 else { return 0 }
        let absHandicap = abs(courseHandicap)
        let sign = courseHandicap >= 0 ? 1 : -1
        let fullStrokes = absHandicap / totalHoles
        let remainingStrokes = absHandicap % totalHoles
        if holeHandicapRating <= remainingStrokes {
            return (fullStrokes + 1) * sign
        }
        return fullStrokes * sign
    }

    func calculateAndStoreStrokes(holes: [Hole]) {
        let holeHandicaps = holes.sorted { $0.number < $1.number }.map { $0.handicapRating }
        let map = HandicapCalculator.strokesPerHole(courseHandicap: courseHandicap, holeHandicapRatings: holeHandicaps)
        var result: [Int: Int] = [:]
        for hole in holes {
            result[hole.number] = map[hole.number] ?? 0
        }
        strokesReceived = result
    }
}
