
import SwiftUI
import SwiftData

@MainActor
@Observable
final class CourseSetupViewModel {
    var courseName: String = ""
    var city: String = ""
    var state: String = ""
    var slopeRating: String = "113"
    var courseRating: String = "72.0"
    var holeCount: Int = 18
    var holePars: [Int] = Array(repeating: 4, count: 18)
    var holeHandicaps: [Int] = Array(1...18)
    var holeYardages: [String] = Array(repeating: "", count: 18)

    var isValid: Bool { !courseName.isEmpty && !city.isEmpty && !state.isEmpty }

    func createCourse(modelContext: ModelContext) -> Course {
        let course = Course(
            name: courseName, city: city, state: state,
            slopeRating: Int(slopeRating) ?? 113,
            courseRating: Double(courseRating) ?? 72.0
        )
        for i in 0..<holeCount {
            let yardage = Int(holeYardages[i])
            let hole = Hole(number: i + 1, par: holePars[i], handicapRating: holeHandicaps[i], yardage: yardage)
            hole.course = course
            course.holes.append(hole)
        }
        modelContext.insert(course)
        try? modelContext.save()
        return course
    }

    func populateFromAPIResult(_ result: CourseAPIResult) {
        courseName = result.name
        city = result.city
        state = result.state
    }
}
