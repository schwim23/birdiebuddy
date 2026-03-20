import Foundation
import SwiftData

@Model
final class CourseSetup {
    var id: UUID
    var name: String
    var slopeRating: Int       // 55–155; standard scratch is 113
    var courseRatingTimes10: Int // stored as e.g. 720 → displayed "72.0"
    var parArray: [Int]        // 18 values, index 0 = hole 1
    var strokeIndexArray: [Int]// 18 values, each unique in 1–18

    init(
        id: UUID = UUID(),
        name: String,
        slopeRating: Int = 113,
        courseRatingTimes10: Int = 720,
        parArray: [Int] = Array(repeating: 4, count: 18),
        strokeIndexArray: [Int] = CourseSetup.defaultStrokeIndexArray
    ) {
        self.id = id
        self.name = name
        self.slopeRating = slopeRating
        self.courseRatingTimes10 = courseRatingTimes10
        self.parArray = parArray
        self.strokeIndexArray = strokeIndexArray
    }

    /// Default stroke index order matching Course.defaultStrokeIndex (hole 1 → SI 13, etc.)
    static let defaultStrokeIndexArray: [Int] = [
        13, 5, 1, 11, 3, 7, 15, 17, 9,   // holes 1–9
        14, 6, 2, 12, 4, 8, 16, 18, 10    // holes 10–18
    ]

    var courseRating: Double { Double(courseRatingTimes10) / 10.0 }

    /// par for hole n (1-based), falls back to 4
    func par(for hole: Int) -> Int {
        guard (1...18).contains(hole) else { return 4 }
        return parArray[hole - 1]
    }

    /// stroke index for hole n (1-based)
    func strokeIndex(for hole: Int) -> Int {
        guard (1...18).contains(hole) else { return hole }
        return strokeIndexArray[hole - 1]
    }

    var totalPar: Int { parArray.reduce(0, +) }
    var frontNinePar: Int { parArray.prefix(9).reduce(0, +) }
    var backNinePar: Int { parArray.suffix(9).reduce(0, +) }

    /// Convert to the [Int: Int] dictionaries AppState uses internally.
    var parDict: [Int: Int] {
        Dictionary(uniqueKeysWithValues: (1...18).map { ($0, parArray[$0 - 1]) })
    }

    var strokeIndexDict: [Int: Int] {
        Dictionary(uniqueKeysWithValues: (1...18).map { ($0, strokeIndexArray[$0 - 1]) })
    }
}
