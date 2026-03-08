
import Foundation
import SwiftData

@Model
final class Team {
    var id: UUID
    var name: String
    var playerIds: [UUID]

    var game: Game?

    init(id: UUID = UUID(), name: String = "", playerIds: [UUID] = []) {
        self.id = id
        self.name = name
        self.playerIds = playerIds
    }
}
