
import SwiftUI
import SwiftData

struct NewRoundSetupScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = RoundSetupViewModel()
    @State private var createdRound: GolfRound?
    @State private var navigateToScorecard = false
    @State private var showCourseSearch = false
    @State private var showManualCourse = false
    @State private var validationError: String?

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    // Course
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Course", systemImage: "mappin.and.ellipse").font(.headline).foregroundStyle(Theme.textPrimary)
                        if let course = viewModel.selectedCourse {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(course.name).font(.subheadline.bold()).foregroundStyle(Theme.textPrimary)
                                    Text("\(course.city), \(course.state) • Slope: \(course.slopeRating)").font(.caption).foregroundStyle(Theme.textSecondary)
                                }
                                Spacer()
                                Button("Change") { showCourseSearch = true }.font(.caption.bold()).foregroundStyle(Theme.primaryGreen)
                            }.cardStyle()
                        } else {
                            HStack(spacing: 12) {
                                Button { showCourseSearch = true } label: { Label("Search", systemImage: "magnifyingglass").secondaryButtonStyle() }
                                Button { showManualCourse = true } label: { Label("Create", systemImage: "plus").secondaryButtonStyle() }
                            }
                        }
                    }

                    // Holes
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Holes", systemImage: "flag.fill").font(.headline).foregroundStyle(Theme.textPrimary)
                        Picker("Holes", selection: $viewModel.holeCount) {
                            Text("9 Holes").tag(9)
                            Text("18 Holes").tag(18)
                        }.pickerStyle(.segmented)
                    }

                    // Players
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Players", systemImage: "person.3.fill").font(.headline).foregroundStyle(Theme.textPrimary)
                            Spacer()
                            if viewModel.players.count < 4 {
                                Button { viewModel.addPlayer() } label: {
                                    Label("Add", systemImage: "plus.circle.fill").font(.subheadline.bold()).foregroundStyle(Theme.primaryGreen)
                                }
                            }
                        }
                        ForEach(Array(viewModel.players.enumerated()), id: \.element.id) { index, _ in
                            HStack(spacing: 12) {
                                Circle().fill(Theme.primaryGreen.opacity(0.2)).frame(width: 36, height: 36)
                                    .overlay { Text("\(index+1)").font(.subheadline.bold()).foregroundStyle(Theme.primaryGreen) }
                                VStack(spacing: 8) {
                                    TextField("Player Name", text: Binding(get: { viewModel.players[index].name }, set: { viewModel.players[index].name = $0 }))
                                        .textFieldStyle(.roundedBorder)
                                    HStack {
                                        Text("HCP:").font(.caption).foregroundStyle(Theme.textSecondary)
                                        TextField("0", value: Binding(get: { viewModel.players[index].handicap }, set: { viewModel.players[index].handicap = $0 }), format: .number)
                                            .textFieldStyle(.roundedBorder).keyboardType(.decimalPad).frame(width: 80)
                                    }
                                }
                                if viewModel.players.count > 1 {
                                    Button { viewModel.removePlayer(at: index) } label: {
                                        Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.destructive)
                                    }
                                }
                            }.cardStyle()
                        }
                    }

                    // Formats
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Game Formats", systemImage: "trophy.fill").font(.headline).foregroundStyle(Theme.textPrimary)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(GameFormat.allCases) { format in
                                let sel = viewModel.selectedFormats.contains(format)
                                let ok = viewModel.players.count >= format.minPlayers
                                Button {
                                    if sel { viewModel.selectedFormats.remove(format) }
                                    else if ok { viewModel.selectedFormats.insert(format) }
                                } label: {
                                    VStack(spacing: 6) {
                                        Image(systemName: format.iconName).font(.title3)
                                        Text(format.displayName).font(.caption.bold())
                                        Text("\(format.minPlayers)+ players").font(.caption2).opacity(0.7)
                                    }
                                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                                    .background(sel ? Theme.primaryGreen : Theme.cardBackground)
                                    .foregroundStyle(sel ? .white : (ok ? Theme.textPrimary : Theme.textSecondary))
                                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
                                    .overlay { RoundedRectangle(cornerRadius: Theme.cornerRadius).stroke(sel ? Theme.primaryGreen : .gray.opacity(0.2)) }
                                }.disabled(!ok && !sel)
                            }
                        }
                    }

                    if let err = validationError { Text(err).font(.caption).foregroundStyle(Theme.destructive) }

                    Button {
                        if let err = viewModel.validateFormats() { validationError = err }
                        else if !viewModel.canStartRound { validationError = "Select a course and name all players" }
                        else { validationError = nil; createdRound = viewModel.createRound(modelContext: modelContext); if createdRound != nil { navigateToScorecard = true } }
                    } label: { Label("Start Round", systemImage: "play.fill").primaryButtonStyle() }
                    .disabled(!viewModel.canStartRound).opacity(viewModel.canStartRound ? 1 : 0.5)

                    Spacer(minLength: 40)
                }.padding()
            }
        }
        .navigationTitle("New Round").navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        .sheet(isPresented: $showCourseSearch) { NavigationStack { CourseSearchScreen(selectedCourse: $viewModel.selectedCourse) } }
        .sheet(isPresented: $showManualCourse) { NavigationStack { CourseSetupScreen(selectedCourse: $viewModel.selectedCourse) } }
        .navigationDestination(isPresented: $navigateToScorecard) { if let r = createdRound { ScorecardScreen(round: r) } }
    }
}
