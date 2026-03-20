import SwiftUI
import SwiftData

struct CourseSetupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // When editing an existing course, pass it in. nil = creating new.
    var existingCourse: CourseSetup? = nil

    @State private var name: String = ""
    @State private var slopeRating: Int = 113
    @State private var courseRatingTimes10: Int = 720  // 72.0
    @State private var parArray: [Int] = Array(repeating: 4, count: 18)
    @State private var strokeIndexArray: [Int] = CourseSetup.defaultStrokeIndexArray

    private var isNew: Bool { existingCourse == nil }

    var body: some View {
        Form {
            // MARK: Course info
            Section("Course Info") {
                TextField("Course name", text: $name)
                    .accessibilityIdentifier("courseSetup.nameField")

                Stepper("Slope: \(slopeRating)", value: $slopeRating, in: 55...155)

                let ratingStr = String(format: "%.1f", Double(courseRatingTimes10) / 10.0)
                Stepper("Rating: \(ratingStr)", value: $courseRatingTimes10, in: 600...800)
            }

            // MARK: Hole configuration
            Section("Holes") {
                ForEach(0..<18, id: \.self) { i in
                    HoleRow(
                        hole: i + 1,
                        par: $parArray[i],
                        strokeIndex: $strokeIndexArray[i]
                    )
                }
            }

            // MARK: Save
            Section {
                Button(isNew ? "Add Course" : "Save Changes") {
                    save()
                }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("courseSetup.saveButton")

                if !isNew {
                    Button("Delete Course", role: .destructive) {
                        if let course = existingCourse {
                            modelContext.delete(course)
                        }
                        dismiss()
                    }
                }
            }
        }
        .navigationTitle(isNew ? "New Course" : "Edit Course")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadExisting() }
    }

    private func loadExisting() {
        guard let c = existingCourse else { return }
        name = c.name
        slopeRating = c.slopeRating
        courseRatingTimes10 = c.courseRatingTimes10
        parArray = c.parArray
        strokeIndexArray = c.strokeIndexArray
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        if let course = existingCourse {
            course.name = trimmed
            course.slopeRating = slopeRating
            course.courseRatingTimes10 = courseRatingTimes10
            course.parArray = parArray
            course.strokeIndexArray = strokeIndexArray
        } else {
            let course = CourseSetup(
                name: trimmed,
                slopeRating: slopeRating,
                courseRatingTimes10: courseRatingTimes10,
                parArray: parArray,
                strokeIndexArray: strokeIndexArray
            )
            modelContext.insert(course)
        }
        dismiss()
    }
}

// MARK: - Hole Row

private struct HoleRow: View {
    let hole: Int
    @Binding var par: Int
    @Binding var strokeIndex: Int

    var body: some View {
        HStack {
            Text("Hole \(hole)")
                .font(.subheadline)
                .frame(width: 60, alignment: .leading)

            Spacer()

            // Par picker: 3 / 4 / 5
            Picker("Par", selection: $par) {
                Text("3").tag(3)
                Text("4").tag(4)
                Text("5").tag(5)
            }
            .pickerStyle(.segmented)
            .frame(width: 110)

            Spacer()

            // SI stepper
            HStack(spacing: 4) {
                Text("SI")
                    .font(.caption).foregroundStyle(.secondary)
                Stepper("\(strokeIndex)", value: $strokeIndex, in: 1...18)
                    .labelsHidden()
                Text("\(strokeIndex)")
                    .font(.subheadline).monospacedDigit()
                    .frame(width: 24)
            }
        }
    }
}
