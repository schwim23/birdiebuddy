import SwiftUI
import SwiftData

struct SetupView: View {
    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \PlayerProfile.name) private var savedProfiles: [PlayerProfile]
    @Query(sort: \CourseSetup.name)  private var savedCourses: [CourseSetup]

    @State private var roundPlayers: [Player] = []
    @State private var gameFormat: GameFormat = .strokePlay
    @State private var selectedCourseID: UUID? = nil
    @State private var selectedCourseRecord: CourseRecord? = nil
    @State private var selectedTee: String = ""
    @State private var showCoursePicker = false
    @State private var teamAssignment: [UUID: Int] = [:]   // playerID → 0 (A) or 1 (B)
    @State private var newName = ""
    @State private var newHandicap = 0
    @State private var showSavedPlayers = false
    @State private var speechRecognizer = SpeechRecognizer()

    private var selectedCourse: CourseSetup? {
        savedCourses.first { $0.id == selectedCourseID }
    }

    private var availableFormats: [GameFormat] {
        GameFormat.allCases.filter { $0.isCompatible(with: roundPlayers.count) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {

                // MARK: Players in this round
                VStack(alignment: .leading, spacing: 12) {
                    Label("Players", systemImage: "person.2")
                        .font(.headline)

                    if roundPlayers.isEmpty {
                        Text("Add at least one player to start.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        ForEach(roundPlayers) { player in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(player.name).font(.body)
                                    Text("Handicap \(player.handicap)")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button(role: .destructive) {
                                    roundPlayers.removeAll { $0.id == player.id }
                                    teamAssignment.removeValue(forKey: player.id)
                                    resetFormatIfNeeded()
                                } label: {
                                    Image(systemName: "minus.circle").foregroundStyle(.red)
                                }
                            }
                            .padding(.vertical, 4)
                            Divider()
                        }
                    }
                }

                // MARK: Add player form
                VStack(alignment: .leading, spacing: 12) {
                    Label("Add Player", systemImage: "person.badge.plus")
                        .font(.headline)

                    TextField("Name", text: $newName)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityIdentifier("setup.playerNameField")

                    Stepper("Handicap: \(newHandicap)", value: $newHandicap, in: 0...54)
                        .accessibilityIdentifier("setup.handicapStepper")

                    Button("Add Player") {
                        addManualPlayer()
                    }
                    .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .accessibilityIdentifier("setup.addPlayerConfirmButton")
                }

                // MARK: Voice input
                if speechRecognizer.state != .unavailable {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Add by Voice", systemImage: "mic")
                            .font(.headline)

                        Text("Say something like: \"add joe chanley he is a 12 handicap, mike s who is a 14\"")
                            .font(.caption).foregroundStyle(.secondary)

                        Button {
                            toggleVoiceListening()
                        } label: {
                            Label(
                                speechRecognizer.state == .listening ? "Tap to finish" : "Start speaking",
                                systemImage: speechRecognizer.state == .listening ? "waveform" : "mic.fill"
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(speechRecognizer.state == .listening ? Color.red.opacity(0.12) : Color.green.opacity(0.12))
                            .foregroundStyle(speechRecognizer.state == .listening ? .red : .green)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .accessibilityIdentifier("setup.micButton")

                        if !speechRecognizer.lastHeardText.isEmpty {
                            Text("\"\(speechRecognizer.lastHeardText)\"")
                                .font(.caption).foregroundStyle(.secondary)
                                .accessibilityIdentifier("setup.voiceFeedbackLabel")
                        }
                    }
                }

                // MARK: Saved players
                if !savedProfiles.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Button {
                            withAnimation { showSavedPlayers.toggle() }
                        } label: {
                            HStack {
                                Label("Saved Players", systemImage: "person.crop.circle")
                                    .font(.headline)
                                Spacer()
                                Image(systemName: showSavedPlayers ? "chevron.up" : "chevron.down")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .foregroundStyle(.primary)

                        if showSavedPlayers {
                            ForEach(savedProfiles) { profile in
                                let alreadyAdded = roundPlayers.contains {
                                    $0.name.lowercased() == profile.name.lowercased()
                                }
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(profile.name).font(.body)
                                        Text("Handicap \(profile.handicap)").font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Button(alreadyAdded ? "Added" : "Add") {
                                        if !alreadyAdded {
                                            roundPlayers.append(profile.asPlayer)
                                            resetFormatIfNeeded()
                                        }
                                    }
                                    .disabled(alreadyAdded)
                                    .buttonStyle(.bordered)
                                    .tint(alreadyAdded ? .gray : .blue)
                                }
                                Divider()
                            }
                        }
                    }
                }

                // MARK: Course
                VStack(alignment: .leading, spacing: 8) {
                    Label("Course", systemImage: "flag.fill")
                        .font(.headline)

                    Button {
                        showCoursePicker = true
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                if let record = selectedCourseRecord {
                                    Text(record.name).font(.body).foregroundStyle(.primary)
                                    Text("\(record.city), \(record.state) — \(selectedTee) tees")
                                        .font(.caption).foregroundStyle(.secondary)
                                } else if let course = selectedCourse {
                                    Text(course.name).font(.body).foregroundStyle(.primary)
                                    Text("Custom course").font(.caption).foregroundStyle(.secondary)
                                } else {
                                    Text("Default (Par 72)").font(.body).foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .accessibilityIdentifier("setup.coursePickerButton")

                    if selectedCourseRecord == nil {
                        Picker("Custom Course", selection: $selectedCourseID) {
                            Text("Default (Par 72)").tag(UUID?.none)
                            ForEach(savedCourses) { course in
                                Text(course.name).tag(UUID?.some(course.id))
                            }
                        }
                        .pickerStyle(.menu)
                        .accessibilityIdentifier("setup.coursePicker")
                    }

                    if let course = selectedCourse, selectedCourseRecord == nil {
                        Button {
                            router.navigate(to: .editCourse(course))
                        } label: {
                            Label("Edit \(course.name)", systemImage: "pencil")
                                .font(.subheadline)
                        }
                    }
                }
                .sheet(isPresented: $showCoursePicker) {
                    CoursePickerView { record, tee in
                        selectedCourseRecord = record
                        selectedTee = tee
                        selectedCourseID = nil
                    }
                }

                // MARK: Game format
                if availableFormats.count > 1 {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Format", systemImage: "flag")
                            .font(.headline)

                        Picker("Format", selection: $gameFormat) {
                            ForEach(availableFormats, id: \.self) { format in
                                Text(format.rawValue).tag(format)
                            }
                        }
                        .pickerStyle(.menu)
                        .accessibilityIdentifier("setup.formatPicker")

                        // Team assignment for Best Ball (4 players)
                        if gameFormat == .bestBall && roundPlayers.count == 4 {
                            teamAssignmentSection
                        }
                    }
                }

                // MARK: Start round
                Button("Start Round") {
                    startRound()
                }
                .disabled(roundPlayers.isEmpty)
                .font(.title3)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(roundPlayers.isEmpty ? Color.gray.opacity(0.3) : Color.green)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .accessibilityIdentifier("setup.startRoundButton")
            }
            .padding()
        }
        .navigationTitle("New Round")
        .task { _ = await speechRecognizer.requestPermissions() }
        .onDisappear { speechRecognizer.stopListening() }
    }

    // MARK: - Team Assignment (Best Ball)

    private var teamAssignmentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Team Assignment")
                .font(.subheadline).fontWeight(.medium)

            ForEach(roundPlayers) { player in
                teamRow(for: player)
            }
        }
        .accessibilityIdentifier("setup.teamAssignment")
    }

    private func teamRow(for player: Player) -> some View {
        HStack {
            Text(player.name).font(.body)
            Spacer()
            Picker("", selection: Binding(
                get: { teamAssignment[player.id] ?? (defaultTeamIndex(for: player)) },
                set: { teamAssignment[player.id] = $0 }
            )) {
                Text("Team A").tag(0)
                Text("Team B").tag(1)
            }
            .pickerStyle(.segmented)
            .frame(width: 160)
            .labelsHidden()
        }
        .padding(.vertical, 2)
    }

    private func defaultTeamIndex(for player: Player) -> Int {
        roundPlayers.firstIndex(where: { $0.id == player.id }).map { $0 % 2 } ?? 0
    }

    // MARK: - Helpers

    private func effectiveTeams() -> [UUID: Int] {
        var result = [UUID: Int]()
        for player in roundPlayers {
            result[player.id] = teamAssignment[player.id] ?? defaultTeamIndex(for: player)
        }
        return result
    }

    private func resetFormatIfNeeded() {
        if !availableFormats.contains(gameFormat) {
            gameFormat = .strokePlay
        }
    }

    private func startRound() {
        let format = availableFormats.contains(gameFormat) ? gameFormat : .strokePlay
        let teams = gameFormat.isTeamFormat ? effectiveTeams() : [:]
        if let record = selectedCourseRecord {
            appState.startRound(with: roundPlayers, format: format,
                                courseRecord: record, tee: selectedTee, teams: teams)
        } else {
            appState.startRound(with: roundPlayers, format: format,
                                course: selectedCourse, teams: teams)
        }
        router.navigate(to: .round)
    }

    private func addManualPlayer() {
        let name = newName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let player = Player(name: name, handicap: newHandicap)
        roundPlayers.append(player)
        upsertProfile(for: player)
        resetFormatIfNeeded()
        newName = ""
        newHandicap = 0
    }

    private func toggleVoiceListening() {
        if speechRecognizer.state == .listening {
            let transcript = speechRecognizer.lastHeardText
            speechRecognizer.stopListening()
            addPlayersFromTranscript(transcript)
        } else {
            speechRecognizer.lastHeardText = ""
            speechRecognizer.startListeningForText()
        }
    }

    private func addPlayersFromTranscript(_ text: String) {
        guard !text.isEmpty else { return }
        for p in PlayerParser.parse(text) {
            let player = Player(name: p.name, handicap: p.handicap ?? 0)
            guard !roundPlayers.contains(where: { $0.name.lowercased() == player.name.lowercased() }) else { continue }
            roundPlayers.append(player)
            upsertProfile(for: player)
        }
        resetFormatIfNeeded()
    }

    private func upsertProfile(for player: Player) {
        if let existing = savedProfiles.first(where: { $0.name.lowercased() == player.name.lowercased() }) {
            existing.handicap = player.handicap
        } else {
            modelContext.insert(PlayerProfile(id: player.id, name: player.name, handicap: player.handicap))
        }
    }
}
