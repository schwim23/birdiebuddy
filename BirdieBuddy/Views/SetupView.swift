import SwiftUI
import SwiftData

struct SetupView: View {
    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \PlayerProfile.name) private var savedProfiles: [PlayerProfile]

    @State private var roundPlayers: [Player] = []
    @State private var gameFormat: GameFormat = .strokePlay
    @State private var newName = ""
    @State private var newHandicap = 0
    @State private var showSavedPlayers = false
    @State private var speechRecognizer = SpeechRecognizer()

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

                // MARK: Game format (match play only available for 2 players)
                if roundPlayers.count == 2 {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Format", systemImage: "flag")
                            .font(.headline)
                        Picker("Format", selection: $gameFormat) {
                            ForEach(GameFormat.allCases, id: \.self) { format in
                                Text(format.rawValue).tag(format)
                            }
                        }
                        .pickerStyle(.segmented)
                        .accessibilityIdentifier("setup.formatPicker")
                    }
                }

                // MARK: Start round
                Button("Start Round") {
                    appState.startRound(with: roundPlayers, format: roundPlayers.count == 2 ? gameFormat : .strokePlay)
                    router.navigate(to: .round)
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

    // MARK: - Helpers

    private func addManualPlayer() {
        let name = newName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let player = Player(name: name, handicap: newHandicap)
        roundPlayers.append(player)
        upsertProfile(for: player)
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
    }

    /// Insert or update a PlayerProfile in SwiftData.
    private func upsertProfile(for player: Player) {
        if let existing = savedProfiles.first(where: { $0.name.lowercased() == player.name.lowercased() }) {
            existing.handicap = player.handicap
        } else {
            modelContext.insert(PlayerProfile(id: player.id, name: player.name, handicap: player.handicap))
        }
    }
}
