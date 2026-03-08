
import Foundation
import SwiftData

@Model
final class TournamentPlayer {
    var id: UUID
    var playerId: UUID
    var displayName: String
    var handicapIndex: Double
    var teamTag: String
    var isOrganizer: Bool
    var joinedAt: Date
    var cumulativePointsData: Data?

    var tournament: Tournament?

    init(
        id: UUID = UUID(),
        playerId: UUID = UUID(),
        displayName: String = "",
        handicapIndex: Double = 0.0,
        teamTag: String = "",
        isOrganizer: Bool = false,
        joinedAt: Date = Date()
    ) {
        self.id = id
        self.playerId = playerId
        self.displayName = displayName
        self.handicapIndex = handicapIndex
        self.teamTag = teamTag
        self.isOrganizer = isOrganizer
        self.joinedAt = joinedAt
    }

    /// Cumulative points across all tournament rounds, keyed by GameFormat rawValue
    var cumulativePoints: [String: Double] {
        get {
            guard let data = cumulativePointsData else { return [:] }
            return (try? JSONDecoder().decode([String: Double].self, from: data)) ?? [:]
        }
        set {
            cumulativePointsData = try? JSONEncoder().encode(newValue)
        }
    }

    var totalPoints: Double {
        cumulativePoints.values.reduce(0, +)
    }
}
