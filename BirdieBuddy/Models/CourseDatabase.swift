import Foundation

/// Loads and searches the bundled course dataset.
/// The full dataset is decoded once at first access and cached in memory.
enum CourseDatabase {

    static let shared: [CourseRecord] = {
        guard let url  = Bundle.main.url(forResource: "courses", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let list = try? JSONDecoder().decode([CourseRecord].self, from: data)
        else { return [] }
        return list.sorted { $0.name < $1.name }
    }()

    /// Returns courses whose name or city contains `query` (case-insensitive).
    /// Returns all courses when `query` is empty.
    static func search(_ query: String) -> [CourseRecord] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return shared }
        return shared.filter {
            $0.name.lowercased().contains(q) || $0.city.lowercased().contains(q)
        }
    }

    /// Look up a single course by its stable UUID.
    static func find(id: UUID) -> CourseRecord? {
        shared.first { $0.id == id }
    }
}
