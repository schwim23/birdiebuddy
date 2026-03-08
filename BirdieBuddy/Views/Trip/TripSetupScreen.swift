
import SwiftUI
import SwiftData

struct TripSetupScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @State private var vm = TripViewModel()

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    TextField("Trip Name", text: $vm.tripName).textFieldStyle(.roundedBorder)
                    DatePicker("Start", selection: $vm.startDate, displayedComponents: .date)
                    DatePicker("End", selection: $vm.endDate, displayedComponents: .date)
                    Button {
                        let _ = vm.createTrip(organizerId: appState.currentUser?.id ?? UUID(), modelContext: modelContext)
                        dismiss()
                    } label: { Text("Create Trip").primaryButtonStyle() }
                    .disabled(vm.tripName.isEmpty)
                }.padding()
            }
        }
        .navigationTitle("New Trip").navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
    }
}
