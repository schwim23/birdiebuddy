
import SwiftUI
import SwiftData

struct CourseSetupScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCourse: Course?
    @State private var vm = CourseSetupViewModel()

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Course Info", systemImage: "mappin").font(.headline).foregroundStyle(Theme.textPrimary)
                        TextField("Course Name", text: $vm.courseName).textFieldStyle(.roundedBorder)
                        HStack { TextField("City", text: $vm.city).textFieldStyle(.roundedBorder); TextField("State", text: $vm.state).textFieldStyle(.roundedBorder).frame(width: 80) }
                        HStack { TextField("Slope", text: $vm.slopeRating).textFieldStyle(.roundedBorder).keyboardType(.numberPad); TextField("Rating", text: $vm.courseRating).textFieldStyle(.roundedBorder).keyboardType(.decimalPad) }
                        Picker("Holes", selection: $vm.holeCount) { Text("9").tag(9); Text("18").tag(18) }.pickerStyle(.segmented)
                    }.cardStyle()

                    VStack(alignment: .leading, spacing: 12) {
                        Label("Hole Details", systemImage: "flag.fill").font(.headline).foregroundStyle(Theme.textPrimary)
                        ForEach(0..<vm.holeCount, id: \.self) { i in
                            HStack(spacing: 8) {
                                Text("#\(i+1)").font(.caption.bold()).frame(width: 30).foregroundStyle(Theme.textSecondary)
                                Picker("Par", selection: Binding(get: { vm.holePars[i] }, set: { vm.holePars[i] = $0 })) {
                                    Text("3").tag(3); Text("4").tag(4); Text("5").tag(5)
                                }.pickerStyle(.segmented).frame(width: 120)
                                Text("HCP:").font(.caption).foregroundStyle(Theme.textSecondary)
                                TextField("", value: Binding(get: { vm.holeHandicaps[i] }, set: { vm.holeHandicaps[i] = $0 }), format: .number)
                                    .textFieldStyle(.roundedBorder).keyboardType(.numberPad).frame(width: 50)
                            }
                        }
                    }.cardStyle()

                    Button {
                        let course = vm.createCourse(modelContext: modelContext)
                        selectedCourse = course; dismiss()
                    } label: { Text("Save Course").primaryButtonStyle() }
                    .disabled(!vm.isValid).opacity(vm.isValid ? 1 : 0.5)
                    Spacer(minLength: 40)
                }.padding()
            }
        }
        .navigationTitle("Create Course").navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
    }
}
