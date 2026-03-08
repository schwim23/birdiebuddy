
import Foundation

struct CourseAPIResult: Identifiable {
    var id = UUID()
    var name: String
    var city: String
    var state: String
    var latitude: Double?
    var longitude: Double?
}

// TODO: Replace with real golf course API (e.g. GolfCourseAPI.com). Currently uses sample data for MVP.
@MainActor
@Observable
final class CourseAPIService {
    var searchResults: [CourseAPIResult] = []
    var isSearching: Bool = false

    func searchCourses(query: String) async {
        guard !query.isEmpty else { searchResults = []; return }
        isSearching = true
        try? await Task.sleep(nanoseconds: 200_000_000)
        searchResults = Self.sampleDB.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.city.localizedCaseInsensitiveContains(query)
        }
        isSearching = false
    }

    func searchNearby(latitude: Double, longitude: Double) async {
        isSearching = true
        try? await Task.sleep(nanoseconds: 200_000_000)
        searchResults = Self.sampleDB.filter { c in
            guard let lat = c.latitude, let lng = c.longitude else { return false }
            return sqrt(pow(lat - latitude, 2) + pow(lng - longitude, 2)) < 1.0
        }
        isSearching = false
    }

    static let sampleDB: [CourseAPIResult] = [
        .init(name: "Pebble Beach Golf Links", city: "Pebble Beach", state: "CA", latitude: 36.57, longitude: -121.95),
        .init(name: "Augusta National Golf Club", city: "Augusta", state: "GA", latitude: 33.50, longitude: -82.02),
        .init(name: "Pinehurst No. 2", city: "Pinehurst", state: "NC", latitude: 35.19, longitude: -79.47),
        .init(name: "TPC Sawgrass", city: "Ponte Vedra Beach", state: "FL", latitude: 30.20, longitude: -81.39),
        .init(name: "Torrey Pines South", city: "San Diego", state: "CA", latitude: 32.89, longitude: -117.25),
        .init(name: "Bethpage Black", city: "Farmingdale", state: "NY", latitude: 40.75, longitude: -73.45),
        .init(name: "Whistling Straits", city: "Sheboygan", state: "WI", latitude: 43.85, longitude: -87.73),
        .init(name: "Kiawah Island Ocean Course", city: "Kiawah Island", state: "SC", latitude: 32.61, longitude: -80.08),
        .init(name: "Bandon Dunes", city: "Bandon", state: "OR", latitude: 43.19, longitude: -124.38),
        .init(name: "Oakmont Country Club", city: "Oakmont", state: "PA", latitude: 40.53, longitude: -79.83),
    ]
}
