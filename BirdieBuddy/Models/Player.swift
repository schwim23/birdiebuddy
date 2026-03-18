import Foundation

struct Player: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var handicap: Int

    init(id: UUID = UUID(), name: String, handicap: Int = 0) {
        self.id = id
        self.name = name
        self.handicap = handicap
    }
}
