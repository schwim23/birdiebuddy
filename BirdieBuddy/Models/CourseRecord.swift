import Foundation

struct CourseHole: Codable {
    let number: Int           // 1–18
    let par: Int              // 3, 4, or 5
    let strokeIndex: Int      // 1–18 (1 = hardest)
    let yardages: [String: Int]  // tee name → yards
}

struct CourseRecord: Codable, Identifiable {
    let id: UUID
    let name: String
    let city: String
    let state: String         // e.g. "CA", "NY"
    let country: String       // e.g. "US"
    let holes: [CourseHole]   // always 18 elements, ordered 1–18
    let tees: [String]        // longest → shortest
    let slopeRating: [String: Int]      // tee → slope (55–155)
    let courseRating: [String: Double]  // tee → rating (e.g. 74.2)
    let source: CourseDataSource

    /// Par for a given hole (1-based). Falls back to 4 if not found.
    func par(for hole: Int) -> Int {
        holes.first { $0.number == hole }?.par ?? 4
    }

    /// Stroke index for a given hole (1-based). Falls back to hole number if not found.
    func strokeIndex(for hole: Int) -> Int {
        holes.first { $0.number == hole }?.strokeIndex ?? hole
    }

    /// [Int: Int] par dictionary compatible with AppState.
    var parDict: [Int: Int] {
        Dictionary(uniqueKeysWithValues: holes.map { ($0.number, $0.par) })
    }

    /// [Int: Int] stroke index dictionary compatible with AppState.
    var strokeIndexDict: [Int: Int] {
        Dictionary(uniqueKeysWithValues: holes.map { ($0.number, $0.strokeIndex) })
    }

    var totalPar: Int { holes.reduce(0) { $0 + $1.par } }
}

enum CourseDataSource: String, Codable {
    case bundled      // shipped with app
    case userCreated  // entered manually via CourseSetupView
    case api          // fetched from live API (future)
}
