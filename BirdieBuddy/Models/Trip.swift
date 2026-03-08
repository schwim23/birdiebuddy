
import Foundation
import SwiftData

@Model
final class Trip {
    var id: UUID
    var name: String
    var startDate: Date
    var endDate: Date
    var inviteCode: String
    var organizerId: UUID

    @Relationship(deleteRule: .nullify)
    var members: [UserProfile] = []

    @Relationship(deleteRule: .nullify)
    var rounds: [GolfRound] = []

    init(
        id: UUID = UUID(),
        name: String = "",
        startDate: Date = Date(),
        endDate: Date = Date(),
        inviteCode: String = "",
        organizerId: UUID = UUID()
    ) {
        self.id = id
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.inviteCode = inviteCode.isEmpty ? Self.generateInviteCode() : inviteCode
        self.organizerId = organizerId
    }

    static func generateInviteCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<6).map { _ in chars.randomElement() ?? "A" })
    }
}
