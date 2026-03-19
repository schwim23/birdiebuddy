import SwiftUI

struct RoundView: View {
    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router
    @State private var speechRecognizer = SpeechRecognizer()
    @State private var displayHole: Int = 1
    @State private var activePlayer: Player? = nil

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
                    activePlayer = nil
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
                    activePlayer = nil
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
            activePlayer = firstUnscoredPlayer(for: displayHole)
        }
        .onChange(of: appState.currentHole) { _, hole in
            if hole > 18 {
                router.navigate(to: .summary)
            } else {
                displayHole = hole
                activePlayer = firstUnscoredPlayer(for: hole)
            }
        }
        .task {
            _ = await speechRecognizer.requestPermissions()
        }
        .onDisappear {
            speechRecognizer.stopListening()
        }
    }

    // MARK: - Current hole — all players in rows

    @ViewBuilder
    private var currentHoleBody: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(appState.players) { player in
                    playerRow(player: player, hole: displayHole, isPast: false)
                    Divider()
                }
            }
            .padding(.horizontal)

            if speechRecognizer.state != .unavailable, activePlayer != nil {
                micSection.padding(.top, 12)
            }
        }
    }

    // MARK: - Past hole — all players with re-edit

    @ViewBuilder
    private var pastHoleBody: some View {
        Text("Hole \(displayHole) Scores")
            .font(.headline).foregroundStyle(.secondary)

        ScrollView {
            VStack(spacing: 0) {
                ForEach(appState.players) { player in
                    playerRow(player: player, hole: displayHole, isPast: true)
                    Divider()
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Shared player row

    @ViewBuilder
    private func playerRow(player: Player, hole: Int, isPast: Bool) -> some View {
        let isActive = activePlayer?.id == player.id
        let scored = appState.score(for: player, hole: hole)
        let getsStroke = Course.receivesStroke(player, on: hole)

        VStack(spacing: 0) {
            // Row header — always visible
            Button {
                activePlayer = isActive ? nil : player
                speechRecognizer.stopListening()
            } label: {
                HStack(spacing: 12) {
                    Text(player.name)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if getsStroke {
                        Text("●")
                            .font(.caption)
                            .foregroundStyle(.primary)
                    }

                    Text(scored.map { "\($0)" } ?? "—")
                        .font(.body).fontWeight(.semibold)
                        .frame(minWidth: 24, alignment: .trailing)

                    Image(systemName: isActive ? "chevron.up" : "chevron.down")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .padding(.vertical, 12)
            }
            .foregroundStyle(.primary)
            .accessibilityIdentifier("round.playerRow.\(player.id)")

            // Expanded score grid
            if isActive {
                scoreGrid(for: player, hole: hole)
                    .padding(.bottom, 12)
            }
        }
    }

    // MARK: - Score grid

    private func scoreGrid(for player: Player, hole: Int) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
            ForEach(scoreRange, id: \.self) { score in
                let isSelected = appState.score(for: player, hole: hole) == score
                Button("\(score)") {
                    recordScore(score, for: player, hole: hole)
                }
                .font(.title2)
                .frame(width: 60, height: 60)
                .background(isSelected ? Color.blue.opacity(0.6) : Color.blue.opacity(0.12))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .accessibilityIdentifier("round.scoreButton.\(score)")
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Mic

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
        .padding(.horizontal)
    }

    // MARK: - Actions

    private func recordScore(_ score: Int, for player: Player, hole: Int) {
        speechRecognizer.stopListening()
        appState.recordScore(score, forHole: hole, player: player)

        // After recording, move to next un-scored player (if any remain on this hole)
        activePlayer = firstUnscoredPlayer(for: hole)
    }

    private func toggleListening() {
        if speechRecognizer.state == .listening {
            speechRecognizer.stopListening()
        } else {
            guard let player = activePlayer else { return }
            speechRecognizer.startListening(par: par) { score in
                recordScore(score, for: player, hole: displayHole)
            }
        }
    }

    // MARK: - Helpers

    private func firstUnscoredPlayer(for hole: Int) -> Player? {
        appState.players.first { appState.score(for: $0, hole: hole) == nil }
    }
}
