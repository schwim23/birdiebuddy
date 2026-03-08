
import SwiftUI
import SwiftData

struct TournamentSetupScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @State private var viewModel = TournamentSetupViewModel()
    @State private var createdTournament: Tournament?
    @State private var navigateToTournament = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    // Info
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Tournament Info", systemImage: "trophy.fill")
                            .font(.headline).foregroundStyle(Theme.textPrimary)
                        TextField("Tournament Name", text: $viewModel.name).textFieldStyle(.roundedBorder)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Format").font(.subheadline).foregroundStyle(Theme.textSecondary)
                            ForEach(TournamentFormat.allCases) { format in
                                Button {
                                    viewModel.format = format
                                    viewModel.isRyderStyle = format == .ryder
                                } label: {
                                    HStack {
                                        Image(systemName: format.iconName).frame(width: 24)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(format.displayName).font(.subheadline.bold())
                                            Text(format.description).font(.caption).opacity(0.7).lineLimit(2)
                                        }
                                        Spacer()
                                        if viewModel.format == format { Image(systemName: "checkmark.circle.fill") }
                                    }
                                    .padding(12)
                                    .background(viewModel.format == format ? Theme.primaryGreen : Theme.cardBackground)
                                    .foregroundStyle(viewModel.format == format ? .white : Theme.textPrimary)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }
                    }

                    // Dates & Rounds
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Schedule", systemImage: "calendar").font(.headline).foregroundStyle(Theme.textPrimary)
                        DatePicker("Start", selection: $viewModel.startDate, displayedComponents: .date)
                        DatePicker("End", selection: $viewModel.endDate, displayedComponents: .date)
                        Stepper("Rounds: \(viewModel.numberOfRounds)", value: Binding(
                            get: { viewModel.numberOfRounds },
                            set: { viewModel.updateRoundCount($0) }
                        ), in: 1...10)
                        ForEach(0..<viewModel.numberOfRounds, id: \.self) { i in
                            HStack {
                                Text("R\(i+1):").font(.caption).foregroundStyle(Theme.textSecondary)
                                TextField("Course Name", text: Binding(
                                    get: { i < viewModel.roundCourseNames.count ? viewModel.roundCourseNames[i] : "" },
                                    set: { if i < viewModel.roundCourseNames.count { viewModel.roundCourseNames[i] = $0 } }
                                )).textFieldStyle(.roundedBorder)
                            }
                        }
                    }.cardStyle()

                    // Players
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Players (\(viewModel.playerCount))", systemImage: "person.3.fill")
                                .font(.headline).foregroundStyle(Theme.textPrimary)
                            Spacer()
                            Button { viewModel.addPlayer() } label: {
                                Label("Add", systemImage: "plus.circle.fill").font(.subheadline.bold()).foregroundStyle(Theme.primaryGreen)
                            }
                        }
                        ForEach(Array(viewModel.playerEntries.enumerated()), id: \.element.id) { index, _ in
                            HStack(spacing: 8) {
                                Text("\(index+1)").font(.caption.bold()).foregroundStyle(Theme.primaryGreen).frame(width: 20)
                                TextField("Name", text: Binding(
                                    get: { viewModel.playerEntries[index].name },
                                    set: { viewModel.playerEntries[index].name = $0 }
                                )).textFieldStyle(.roundedBorder)
                                TextField("HCP", value: Binding(
                                    get: { viewModel.playerEntries[index].handicap },
                                    set: { viewModel.playerEntries[index].handicap = $0 }
                                ), format: .number).textFieldStyle(.roundedBorder).keyboardType(.decimalPad).frame(width: 60)
                                if viewModel.isRyderStyle {
                                    Picker("", selection: Binding(
                                        get: { viewModel.playerEntries[index].teamTag },
                                        set: { viewModel.playerEntries[index].teamTag = $0 }
                                    )) { Text("—").tag(""); Text("A").tag("Team A"); Text("B").tag("Team B") }
                                    .pickerStyle(.segmented).frame(width: 100)
                                }
                                if viewModel.playerEntries.count > 2 {
                                    Button { viewModel.removePlayer(at: index) } label: {
                                        Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.destructive)
                                    }
                                }
                            }
                        }
                    }.cardStyle()

                    // Game Formats
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Game Formats", systemImage: "trophy.fill").font(.headline).foregroundStyle(Theme.textPrimary)
                        Text("Results carry across rounds.").font(.caption).foregroundStyle(Theme.textSecondary)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(GameFormat.allCases) { format in
                                let sel = viewModel.selectedGameFormats.contains(format)
                                Button {
                                    if sel { viewModel.selectedGameFormats.remove(format) }
                                    else { viewModel.selectedGameFormats.insert(format) }
                                } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: format.iconName).font(.title3)
                                        Text(format.displayName).font(.caption.bold())
                                    }
                                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                                    .background(sel ? Theme.primaryGreen : Theme.cardBackground)
                                    .foregroundStyle(sel ? .white : Theme.textPrimary)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay { RoundedRectangle(cornerRadius: 10).stroke(sel ? Theme.primaryGreen : .gray.opacity(0.2)) }
                                }
                            }
                        }
                        Toggle("Net Scoring", isOn: $viewModel.useNetScoring)
                        Toggle("Nassau Carry-Over", isOn: $viewModel.carryOverNassau)
                    }.cardStyle()

                    // Create
                    Button {
                        let orgId = appState.currentUser?.id ?? UUID()
                        createdTournament = viewModel.createTournament(organizerId: orgId, modelContext: modelContext)
                        navigateToTournament = true
                    } label: { Label("Create Tournament", systemImage: "trophy.fill").primaryButtonStyle() }
                    .disabled(!viewModel.canCreate).opacity(viewModel.canCreate ? 1 : 0.5)

                    Spacer(minLength: 40)
                }.padding()
            }
        }
        .navigationTitle("New Tournament").navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        .navigationDestination(isPresented: $navigateToTournament) {
            if let t = createdTournament { TournamentHubScreen(tournament: t) }
        }
    }
}
