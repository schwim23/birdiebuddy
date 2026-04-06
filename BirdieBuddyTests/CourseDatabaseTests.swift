import Testing
@testable import BirdieBuddy

@Suite("CourseDatabase")
struct CourseDatabaseTests {

    @Test("shared loads at least one course")
    func sharedLoadsData() {
        #expect(!CourseDatabase.shared.isEmpty)
    }

    @Test("search empty query returns all courses")
    func searchEmptyReturnsAll() {
        let all = CourseDatabase.search("")
        #expect(all.count == CourseDatabase.shared.count)
    }

    @Test("search by name is case-insensitive")
    func searchByName() {
        let results = CourseDatabase.search("pebble")
        #expect(results.contains { $0.name.lowercased().contains("pebble") })
    }

    @Test("search by city")
    func searchByCity() {
        let results = CourseDatabase.search("sawgrass")
        #expect(!results.isEmpty)
    }

    @Test("search with no match returns empty")
    func searchNoMatch() {
        let results = CourseDatabase.search("zzznomatch999")
        #expect(results.isEmpty)
    }

    @Test("find returns course by id")
    func findById() {
        guard let first = CourseDatabase.shared.first else { return }
        let found = CourseDatabase.find(id: first.id)
        #expect(found?.id == first.id)
    }

    @Test("find returns nil for unknown id")
    func findUnknownId() {
        let found = CourseDatabase.find(id: .init())
        #expect(found == nil)
    }

    @Test("every course has exactly 18 holes")
    func coursesHave18Holes() {
        for course in CourseDatabase.shared {
            #expect(course.holes.count == 18, "Expected 18 holes in \(course.name)")
        }
    }

    @Test("hole numbers are 1 through 18")
    func holeNumbers() {
        for course in CourseDatabase.shared {
            let nums = Set(course.holes.map(\.number))
            #expect(nums == Set(1...18), "\(course.name) has unexpected hole numbers")
        }
    }

    @Test("parDict contains all 18 holes")
    func parDict() {
        guard let course = CourseDatabase.shared.first else { return }
        #expect(course.parDict.count == 18)
    }

    @Test("strokeIndexDict contains all 18 holes")
    func strokeIndexDict() {
        guard let course = CourseDatabase.shared.first else { return }
        #expect(course.strokeIndexDict.count == 18)
    }

    @Test("par helper falls back to 4 for unknown hole")
    func parFallback() {
        guard let course = CourseDatabase.shared.first else { return }
        #expect(course.par(for: 99) == 4)
    }

    @Test("strokeIndex helper falls back to hole number")
    func strokeIndexFallback() {
        guard let course = CourseDatabase.shared.first else { return }
        #expect(course.strokeIndex(for: 99) == 99)
    }

    @Test("totalPar is reasonable (54–90)")
    func totalPar() {
        for course in CourseDatabase.shared {
            #expect((54...90).contains(course.totalPar), "\(course.name) has unreasonable totalPar \(course.totalPar)")
        }
    }

    @Test("tees list is non-empty")
    func teesNonEmpty() {
        for course in CourseDatabase.shared {
            #expect(!course.tees.isEmpty, "\(course.name) has no tees")
        }
    }
}
