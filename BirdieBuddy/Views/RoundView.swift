import SwiftUI

struct RoundView: View {
    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router
    @State private var speechRecognizer = SpeechRecognizer()
    @State private var displayHole: Int = 1
    @State private var editingPlayer: Player? = nil

    private let par = 4
    private let scoreRange = 1...9

    private var isOnLeadingHole: Bool { displayHole == appState.currentHole }
    private var canGoBack: Bool { displayHole > 1 }
    private var canGoForward: Bool { displayHole < appState.currentHole }

    var body: some View {
        VStack(spacing: 20) {

            // MARK: Hole navigation header
            HStack(spacing: 24) {
                Button {
                    displayHole -= 1
                    editingPlayer = nil
                    speechRecognizer.stopListening()
                } label: {
                    Image(systemName: "chevron.left").font(.title2).frame(width: 44, height: 44)
                }
                .disabled(!canGoBack)
                .accessibilityIdentifier("round.prevHoleButton")

                VStack(spacing: 4) {
                    Text("Hole \(displayHole)")
                        .font(.largeTitle).fontWeight(.bold)
                        .accessibilityIdentifier("round.holeLabel")
                    Text("Par \(par)")
                        .font(.title2).foregroundStyle(.secondary)
                        .accessibilityIdentifier("round.parLabel")
                }

                Button {
                    displayHole += 1
                    editingPlayer = nil
                    speechRecognizer.stopListening()
                } label: {
                    Image(systemName: "chevron.right").font(.title2).frame(width: 44, height: 44)
                }
                .disabled(!canGoForward)
                .accessibilityIdentifier("round.nextHoleButton")
            }
            .padding(.top, 32)

            if isOnLeadingHole {
                currentHoleBody
            } else {
                pastHoleBody
            }

            Spacer()
        }
        .navigationTitle("Round in Progress")
        .navigationBarBackButtonHidden(true)
        .onAppear {
            displayHole = appState.currentHole
        }
        .onChange(of: appState.currentHole) { _, hole in
            if hole > 18 {
                router.navigate(to: .summary)
            }
        }
        .task {
            _ = await speechRecognizer.requestPermissions()
        }
        .onDisappear {
            speechRecognizer.stopListening()
        }
    }

    // MARK: - Current hole

    @ViewBuilder
    private var currentHoleBody: some View {
        if let player = appState.currentPlayer {
            VStack(spacing: 6) {
                Text(player.name)
                    .font(.title3).fontWeight(.semibold)
                    .accessibilityIdentifier("round.playerLabel")
                Text("Player \(appState.currentPlayerIndex + 1) of \(appState.players.count)")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }

        if let player = appState.currentPlayer,
           let score = appState.score(for: player, hole: displayHole) {
            Text("Score: \(score)")
                .font(.title3)
                .accessibilityIdentifier("round.currentScoreLabel")
        }

        Spacer()
        Text("Select your score").font(.headline).foregroundStyle(.secondary)
        scoreGrid(for: appState.currentPlayer, hole: displayHole)

        if speechRecognizer.state != .unavailable {
            micSection
        }
    }

    // MARK: - Past hole

    @ViewBuilder
    private var pastHoleBody: some View {
        Text("Hole \(displayHole) Scores").font(.headline).foregroundStyle(.secondary)

        VStack(spacing: 8) {
            ForEach(appState.players) { player in
                let score = appState.score(for: player, hole: displayHole)
                let isEditing = editingPlayer?.id == player.id

                VStack(spacing: 8) {
                    Button {
                        editingPlayer = isEditing ? nil : player
                    } label: {
                        HStack {
                            Text(player.name).font(.body)
                            Spacer()
                            Text(score.map { "\($0)" } ?? "—").font(.body).fontWeight(.semibold)
                            Image(systemName: isEditing ? "chevron.up" : "pencil")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 6)
                    }
                    .foregroundStyle(.primary)

                    if isEditing {
                        scoreGrid(for: player, hole: displayHole)
                    }
                }
                Divider()
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Shared

    private func scoreGrid(for player: Player?, hole: Int) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
            ForEach(scoreRange, id: \.self) { score in
                let isSelected = player.flatMap { appState.score(for: $0, hole: hole) } == score
                Button("\(score)") {
                    if let p = player { recordScore(score, for: p, hole: hole) }
                }
                .font(.title2)
                .frame(width: 60, height: 60)
                .background(isSelected ? Color.blue.opacity(0.6) : Color.blue.opacity(0.12))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .accessibilityIdentifier("round.scoreButton.\(score)")
            }
        }
        .padding(.horizontal)
    }

    private var micSection: some View {
        VStack(spacing: 8) {
            Button { toggleListening() } label: {
                Label(
                    speechRecognizer.state == .listening ? "Listening…" : "Say Your Score",
                    systemImage: speechRecognizer.state == .listening ? "waveform" : "mic"
                )
                .font(.headline)
                .padding(.horizontal, 24).padding(.vertical, 14)
                .background(speechRecognizer.state == .listening ? Color.red.opacity(0.15) : Color.green.opacity(0.15))
                .foregroundStyle(speechRecognizer.state == .listening ? .red : .green)
                .clipShape(Capsule())
            }
            .accessibilityIdentifier("round.micButton")

            if !speechRecognizer.lastHeardText.isEmpty {
                Text("Heard: \"\(speechRecognizer.lastHeardText)\"")
                    .font(.caption).foregroundStyle(.secondary)
                    .accessibilityIdentifier("round.voiceFeedbackLabel")
            }
        }
    }

    // MARK: - Actions

    private func recordScore(_ score: Int, for player: Player, hole: Int) {
        let wasLeadingHole = hole == appState.currentHole && player.id == appState.currentPlayer?.id
        speechRecognizer.stopListening()
        appState.recordScore(score, forHole: hole, player: player)
        editingPlayer = nil

        // Navigation handled by .onChange(of: appState.currentHole)
        if !appState.isRoundFinished && wasLeadingHole {
            displayHole = appState.currentHole
        }
    }

    private func toggleListening() {
        if speechRecognizer.state == .listening {
            speechRecognizer.stopListening()
        } else {
            guard let player = appState.currentPlayer else { return }
            speechRecognizer.startListening(par: par) { score in
                recordScore(score, for: player, hole: displayHole)
            }
        }
    }
}
