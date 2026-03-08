
import SwiftUI
import SwiftData

struct CourseSearchScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCourse: Course?
    @State private var courseAPI = CourseAPIService()
    @State private var locationService = LocationService()
    @State private var searchText = ""
    @Query(sort: \Course.name) private var savedCourses: [Course]

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass").foregroundStyle(Theme.textSecondary)
                    TextField("Search courses...", text: $searchText).autocorrectionDisabled()
                    if !searchText.isEmpty { Button { searchText = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.textSecondary) } }
                }.padding().background(Theme.cardBackground)

                Button {
                    locationService.requestPermission()
                    locationService.requestLocation()
                } label: {
                    HStack { Image(systemName: "location.fill"); Text("Find courses near me"); Spacer(); if courseAPI.isSearching { ProgressView() } }
                        .font(.subheadline).foregroundStyle(Theme.primaryGreen).padding()
                }
                Divider()

                ScrollView {
                    LazyVStack(spacing: 8) {
                        if !savedCourses.isEmpty && searchText.isEmpty {
                            Text("Saved Courses").font(.caption.bold()).foregroundStyle(Theme.textSecondary).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal)
                            ForEach(savedCourses) { course in
                                Button { selectedCourse = course; dismiss() } label: {
                                    HStack {
                                        VStack(alignment: .leading) { Text(course.name).font(.subheadline.bold()); Text("\(course.city), \(course.state)").font(.caption) }
                                        Spacer(); Image(systemName: "checkmark.circle").foregroundStyle(Theme.primaryGreen)
                                    }.foregroundStyle(Theme.textPrimary).padding().background(Theme.cardBackground).clipShape(RoundedRectangle(cornerRadius: 10))
                                }.padding(.horizontal)
                            }
                        }
                        if !courseAPI.searchResults.isEmpty {
                            Text("Search Results").font(.caption.bold()).foregroundStyle(Theme.textSecondary).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal)
                            ForEach(courseAPI.searchResults) { result in
                                Button { selectResult(result) } label: {
                                    HStack {
                                        VStack(alignment: .leading) { Text(result.name).font(.subheadline.bold()); Text("\(result.city), \(result.state)").font(.caption) }
                                        Spacer(); Image(systemName: "plus.circle").foregroundStyle(Theme.primaryGreen)
                                    }.foregroundStyle(Theme.textPrimary).padding().background(Theme.cardBackground).clipShape(RoundedRectangle(cornerRadius: 10))
                                }.padding(.horizontal)
                            }
                        }
                    }.padding(.vertical)
                }
            }
        }
        .navigationTitle("Find Course").navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        .onChange(of: searchText) { _, q in Task { await courseAPI.searchCourses(query: q) } }
        .onChange(of: locationService.currentLocation) { _, loc in
            if let l = loc { Task { await courseAPI.searchNearby(latitude: l.coordinate.latitude, longitude: l.coordinate.longitude) } }
        }
    }

    private func selectResult(_ result: CourseAPIResult) {
        let course = Course(name: result.name, city: result.city, state: result.state, latitude: result.latitude, longitude: result.longitude)
        for i in 1...18 { let h = Hole(number: i, par: 4, handicapRating: i); h.course = course; course.holes.append(h) }
        modelContext.insert(course); try? modelContext.save()
        selectedCourse = course; dismiss()
    }
}
