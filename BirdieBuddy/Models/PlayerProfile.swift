import Foundation
import SwiftData

@Model
final class PlayerProfile {
    var id: UUID
    var name: String
    var handicap: Int
    var lastPlayed: Date?

    init(id: UUID = UUID(), name: String, handicap: Int) {
        self.id = id
        self.name = name
        self.handicap = handicap
    }

    var asPlayer: Player {
        Player(id: id, name: name, handicap: handicap)
    }
}
