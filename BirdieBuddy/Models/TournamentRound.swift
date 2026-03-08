
import Foundation
import SwiftData

@Model
final class TournamentRound {
    var id: UUID
    var roundNumber: Int
    var date: Date
    var statusRaw: String
    var courseId: UUID?
    var courseName: String
    var pairingsData: Data?

    var tournament: Tournament?

    @Relationship(deleteRule: .cascade, inverse: \Foursome.tournamentRound)
    var foursomes: [Foursome] = []

    init(
        id: UUID = UUID(),
        roundNumber: Int = 1,
        date: Date = Date(),
        courseName: String = ""
    ) {
        self.id = id
        self.roundNumber = roundNumber
        self.date = date
        self.statusRaw = TournamentRoundStatus.upcoming.rawValue
        self.courseName = courseName
    }

    var status: TournamentRoundStatus {
        get { TournamentRoundStatus(rawValue: statusRaw) ?? .upcoming }
        set { statusRaw = newValue.rawValue }
    }

    /// Pairings: array of arrays of player IDs, each inner array is one foursome
    var pairings: [[UUID]] {
        get {
            guard let data = pairingsData else { return [] }
            return (try? JSONDecoder().decode([[UUID]].self, from: data)) ?? []
        }
        set {
            pairingsData = try? JSONEncoder().encode(newValue)
        }
    }

    var sortedFoursomes: [Foursome] {
        foursomes.sorted { $0.groupNumber < $1.groupNumber }
    }

    var allFoursomesComplete: Bool {
        !foursomes.isEmpty && foursomes.allSatisfy { $0.golfRound?.roundStatus == .completed }
    }
}

enum TournamentRoundStatus: String, Codable {
    case upcoming
    case active
    case completed
}
