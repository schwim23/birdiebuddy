
import Foundation
import SwiftData

@Model
final class Hole {
    var id: UUID
    var number: Int
    var par: Int
    var handicapRating: Int
    var yardage: Int?

    var course: Course?

    init(
        id: UUID = UUID(),
        number: Int = 1,
        par: Int = 4,
        handicapRating: Int = 1,
        yardage: Int? = nil
    ) {
        self.id = id
        self.number = number
        self.par = par
        self.handicapRating = handicapRating
        self.yardage = yardage
    }
}
