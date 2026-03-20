import SwiftUI

struct RoundView: View {
    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router
    @State private var speechRecognizer = SpeechRecognizer()
    @State private var displayHole: Int = 1

    private let par = 4

    private var isOnLeadingHole: Bool { displayHole == appState.currentHole }
    private var canGoBack: Bool { displayHole > 1 }
    private var canGoForward: Bool { displayHole < 18 }

    var body: some View {
        VStack(spacing: 0) {

            // MARK: Hole navigation header
            HStack(spacing: 24) {
                Button {
                    displayHole -= 1
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
                    speechRecognizer.stopListening()
                } label: {
                    Image(systemName: "chevron.right").font(.title2).frame(width: 44, height: 44)
                }
                .disabled(!canGoForward)
                .accessibilityIdentifier("round.nextHoleButton")
            }
            .padding(.top, 32)
            .padding(.bottom, 12)

            // MARK: Match status banner
            if appState.gameFormat == .matchPlay {
                matchStatusBanner.padding(.bottom, 12)
            }

            // MARK: Player score table
            playerTable
                .padding(.horizontal)

            // MARK: Hole result (match play — shown once both players have scored)
            if appState.gameFormat == .matchPlay,
               let result = appState.matchHoleResult(for: displayHole) {
                holeResultView(result).padding(.top, 12)
            }

            // MARK: Mic
            if speechRecognizer.state != .unavailable {
                micSection.padding(.top, 20)
            }

            Spacer()
        }
        .navigationTitle("Round in Progress")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    router.navigate(to: .scorecard)
                } label: {
                    Label("Scorecard", systemImage: "list.bullet")
                }
                .accessibilityIdentifier("round.scorecardButton")
            }
        }
        .onAppear {
            displayHole = appState.currentHole
        }
        .onChange(of: appState.currentHole) { _, hole in
            if hole > 18 {
                router.navigate(to: .summary)
            } else {
                displayHole = hole
            }
        }
        .task {
            _ = await speechRecognizer.requestPermissions()
        }
        .onDisappear {
            speechRecognizer.stopListening()
        }
    }

    // MARK: - Match status banner

    private var matchStatusBanner: some View {
        Text(appState.matchStatusText)
            .font(.headline)
            .padding(.horizontal, 20).padding(.vertical, 8)
            .background(Color.green.opacity(0.12))
            .foregroundStyle(Color.green)
            .clipShape(Capsule())
            .accessibilityIdentifier("round.matchStatusLabel")
    }

    // MARK: - Hole result (match play)

    @ViewBuilder
    private func holeResultView(_ result: HoleResult) -> some View {
        switch result {
        case .playerWins(let p):
            Text("\(p.name) wins the hole")
                .font(.subheadline).foregroundStyle(.primary)
                .padding(.horizontal)
        case .halved:
            Text("Hole halved")
                .font(.subheadline).foregroundStyle(.secondary)
                .padding(.horizontal)
        }
    }

    // MARK: - Player table

    private var playerTable: some View {
        VStack(spacing: 0) {
            ForEach(Array(appState.players.enumerated()), id: \.element.id) { index, player in
                PlayerScoreRow(
                    player: player,
                    index: index,
                    hole: displayHole,
                    existingScore: appState.score(for: player, hole: displayHole),
                    getsStroke: appState.receivesStroke(player, on: displayHole)
                ) { score in
                    appState.recordScore(score, forHole: displayHole, player: player)
                }
                if index < appState.players.count - 1 {
                    Divider().padding(.leading)
                }
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 0.5)
        )
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

    private func toggleListening() {
        if speechRecognizer.state == .listening {
            speechRecognizer.stopListening()
        } else {
            let player = appState.players.first(where: { appState.score(for: $0, hole: displayHole) == nil })
            guard let player else { return }
            speechRecognizer.startListening(par: par) { score in
                appState.recordScore(score, forHole: displayHole, player: player)
            }
        }
    }
}
