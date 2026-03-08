
import Foundation
import SwiftData

@Model
final class Course {
    var id: UUID
    var name: String
    var city: String
    var state: String
    var slopeRating: Int
    var courseRating: Double
    var latitude: Double?
    var longitude: Double?
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Hole.course)
    var holes: [Hole] = []

    init(
        id: UUID = UUID(),
        name: String = "",
        city: String = "",
        state: String = "",
        slopeRating: Int = 113,
        courseRating: Double = 72.0,
        latitude: Double? = nil,
        longitude: Double? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.city = city
        self.state = state
        self.slopeRating = slopeRating
        self.courseRating = courseRating
        self.latitude = latitude
        self.longitude = longitude
        self.createdAt = createdAt
    }

    var sortedHoles: [Hole] {
        holes.sorted { $0.number < $1.number }
    }

    var totalPar: Int {
        holes.reduce(0) { $0 + $1.par }
    }

    var frontNinePar: Int {
        holes.filter { $0.number <= 9 }.reduce(0) { $0 + $1.par }
    }

    var backNinePar: Int {
        holes.filter { $0.number > 9 }.reduce(0) { $0 + $1.par }
    }
}
