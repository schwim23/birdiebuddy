import Foundation
import SwiftData

@Model
final class FavoriteCourse {
    var courseRecordID: UUID
    var name: String           // denormalised for display without loading full record
    var city: String
    var state: String
    var lastPlayedTee: String? // tee selection remembered from last round
    var addedAt: Date

    init(from record: CourseRecord, tee: String? = nil) {
        self.courseRecordID = record.id
        self.name = record.name
        self.city = record.city
        self.state = record.state
        self.lastPlayedTee = tee
        self.addedAt = .now
    }
}
