
import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID
    var displayName: String
    var email: String?
    var handicapIndex: Double
    var profileImageData: Data?
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \RoundPlayer.userProfile)
    var roundPlayers: [RoundPlayer] = []

    init(
        id: UUID = UUID(),
        displayName: String = "",
        email: String? = nil,
        handicapIndex: Double = 0.0,
        profileImageData: Data? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.handicapIndex = handicapIndex
        self.profileImageData = profileImageData
        self.createdAt = createdAt
    }
}
