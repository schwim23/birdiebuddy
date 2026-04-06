import SwiftUI
import SwiftData

/// Sheet that lets the user search the bundled course database,
/// star favorites, pick a tee, or fall back to manual course setup.
struct CoursePickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss

    /// Called when the user confirms a course+tee selection.
    var onSelect: (CourseRecord, String) -> Void

    @Query(sort: \FavoriteCourse.addedAt, order: .reverse)
    private var favorites: [FavoriteCourse]

    @State private var query = ""
    @State private var results: [CourseRecord] = CourseDatabase.shared
    @State private var selectedCourse: CourseRecord? = nil
    @State private var selectedTee: String = ""
    @State private var searchTask: Task<Void, Never>? = nil

    var body: some View {
        NavigationStack {
            List {
                if !favorites.isEmpty && query.isEmpty {
                    favoritesSection
                }
                searchResultsSection
            }
            .listStyle(.insetGrouped)
            .searchable(text: $query, prompt: "Search courses…")
            .onChange(of: query) { _, newValue in
                scheduleSearch(newValue)
            }
            .navigationTitle("Choose Course")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Add Manually") {
                        dismiss()
                        router.navigate(to: .newCourse)
                    }
                    .accessibilityIdentifier("coursePicker.addManuallyButton")
                }
            }
            .sheet(item: $selectedCourse) { course in
                TeePicker(course: course, initialTee: selectedTee) { tee in
                    toggleFavorite(course, tee: tee)
                    onSelect(course, tee)
                    dismiss()
                }
            }
        }
        .accessibilityIdentifier("coursePicker")
    }

    // MARK: - Sections

    private var favoritesSection: some View {
        Section("Favorites") {
            ForEach(favorites) { fav in
                if let record = CourseDatabase.find(id: fav.courseRecordID) {
                    courseRow(record, isFavorite: true)
                }
            }
        }
    }

    private var searchResultsSection: some View {
        Section(query.isEmpty ? "All Courses" : "Results") {
            if results.isEmpty {
                Text("No courses found.")
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("coursePicker.emptyState")
            } else {
                ForEach(results) { course in
                    courseRow(course, isFavorite: isFavorite(course))
                }
            }
        }
    }

    private func courseRow(_ course: CourseRecord, isFavorite: Bool) -> some View {
        HStack(spacing: 12) {
            Button {
                toggleFavoriteOnly(course)
            } label: {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .foregroundStyle(isFavorite ? .yellow : .secondary)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("coursePicker.starButton.\(course.id)")

            VStack(alignment: .leading, spacing: 2) {
                Text(course.name)
                    .font(.body)
                Text("\(course.city), \(course.state)")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption).foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            let lastTee = favorites.first { $0.courseRecordID == course.id }?.lastPlayedTee
            selectedTee = lastTee ?? course.tees.first ?? ""
            selectedCourse = course
        }
        .accessibilityIdentifier("coursePicker.row.\(course.id)")
    }

    // MARK: - Helpers

    private func scheduleSearch(_ text: String) {
        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 200_000_000)
            guard !Task.isCancelled else { return }
            results = CourseDatabase.search(text)
        }
    }

    private func isFavorite(_ course: CourseRecord) -> Bool {
        favorites.contains { $0.courseRecordID == course.id }
    }

    private func toggleFavoriteOnly(_ course: CourseRecord) {
        if let existing = favorites.first(where: { $0.courseRecordID == course.id }) {
            modelContext.delete(existing)
        } else {
            modelContext.insert(FavoriteCourse(from: course))
        }
    }

    private func toggleFavorite(_ course: CourseRecord, tee: String) {
        if let existing = favorites.first(where: { $0.courseRecordID == course.id }) {
            existing.lastPlayedTee = tee
        } else {
            modelContext.insert(FavoriteCourse(from: course, tee: tee))
        }
    }
}

// MARK: - Tee Picker sheet

private struct TeePicker: View {
    let course: CourseRecord
    let initialTee: String
    var onConfirm: (String) -> Void

    @State private var tee: String
    @Environment(\.dismiss) private var dismiss

    init(course: CourseRecord, initialTee: String, onConfirm: @escaping (String) -> Void) {
        self.course = course
        self.initialTee = initialTee
        self.onConfirm = onConfirm
        _tee = State(initialValue: initialTee.isEmpty ? (course.tees.first ?? "") : initialTee)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(course.name) {
                    Text("\(course.city), \(course.state)")
                        .foregroundStyle(.secondary)
                }

                Section("Select Tee") {
                    Picker("Tee", selection: $tee) {
                        ForEach(course.tees, id: \.self) { t in
                            teeRow(t).tag(t)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                    .accessibilityIdentifier("coursePicker.teePicker")
                }
            }
            .navigationTitle("Choose Tee")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Back") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Select") {
                        onConfirm(tee)
                    }
                    .fontWeight(.semibold)
                    .accessibilityIdentifier("coursePicker.confirmTeeButton")
                }
            }
        }
    }

    private func teeRow(_ t: String) -> some View {
        let yardage = course.holes.compactMap { $0.yardages[t] }.reduce(0, +)
        let slope = course.slopeRating[t]
        let rating = course.courseRating[t]
        return VStack(alignment: .leading, spacing: 2) {
            Text(t).font(.body)
            HStack(spacing: 8) {
                if yardage > 0 {
                    Text("\(yardage) yds").font(.caption).foregroundStyle(.secondary)
                }
                if let slope, let rating {
                    Text("Rating \(String(format: "%.1f", rating)) / Slope \(slope)")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }
}
