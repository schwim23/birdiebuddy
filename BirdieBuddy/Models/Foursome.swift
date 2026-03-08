
import Foundation
import SwiftData

@Model
final class Foursome {
    var id: UUID
    var groupNumber: Int
    var groupName: String
    var playerIds: [UUID]
    var playerNames: [String]

    var tournamentRound: TournamentRound?

    @Relationship(deleteRule: .nullify)
    var golfRound: GolfRound?

    init(
        id: UUID = UUID(),
        groupNumber: Int = 1,
        groupName: String = "",
        playerIds: [UUID] = [],
        playerNames: [String] = []
    ) {
        self.id = id
        self.groupNumber = groupNumber
        self.groupName = groupName.isEmpty ? "Group \(groupNumber)" : groupName
        self.playerIds = playerIds
        self.playerNames = playerNames
    }

    var playerCount: Int { playerIds.count }

    var isComplete: Bool {
        golfRound?.roundStatus == .completed
    }
}
