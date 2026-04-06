import SwiftUI

struct RoundView: View {
    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router
    @State private var speechRecognizer = SpeechRecognizer()
    @State private var displayHole: Int = 1
    @State private var isDictatingAll = false
    @State private var showWolfPicker = false

    private var currentPar: Int { appState.par(for: displayHole) }
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
                    Text("Par \(currentPar)")
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

            // MARK: Format status banner
            if !appState.statusText.isEmpty {
                statusBanner.padding(.bottom, 12)
            }

            // MARK: Wolf indicator + decision
            if appState.gameFormat == .wolf {
                wolfHeader.padding(.bottom, 8)
            }

            // MARK: Player score table
            playerTable
                .padding(.horizontal)

            // MARK: Hole result overlay
            if let result = holeResult(for: displayHole) {
                holeResultView(result).padding(.top, 12)
            }

            // MARK: Mic
            if speechRecognizer.state != .unavailable {
                micSection.padding(.top, 20)
            }
            // MARK: Dictate All (multi-player only)
            if appState.players.count > 1, speechRecognizer.state != .unavailable {
                dictateAllSection.padding(.top, 8)
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
        .sheet(isPresented: $showWolfPicker) {
            wolfPickerSheet
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

    // MARK: - Status banner

    private var statusBanner: some View {
        Text(appState.statusText)
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 20).padding(.vertical, 8)
            .background(Color.green.opacity(0.12))
            .foregroundStyle(Color.green)
            .clipShape(Capsule())
            .accessibilityIdentifier("round.matchStatusLabel")
    }

    // MARK: - Wolf header

    private var wolfHeader: some View {
        HStack(spacing: 12) {
            if let wolf = appState.wolfPlayer(for: displayHole) {
                Label("Wolf: \(wolf.name)", systemImage: "pawprint.fill")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.orange)
                    .accessibilityIdentifier("round.wolfIndicator")
            }
            Spacer()
            let decided = appState.wolfHoleStates[displayHole]?.isDecided ?? false
            Button(decided ? "Change Decision" : "Set Wolf Decision") {
                showWolfPicker = true
            }
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(Color.orange.opacity(0.12))
            .foregroundStyle(.orange)
            .clipShape(Capsule())
            .accessibilityIdentifier("round.wolfPicker")
        }
        .padding(.horizontal)
    }

    // MARK: - Wolf picker sheet

    private var wolfPickerSheet: some View {
        NavigationStack {
            List {
                let wolfID = appState.wolfPlayer(for: displayHole)?.id
                let nonWolves = appState.players.filter { $0.id != wolfID }

                Section("Choose Partner") {
                    ForEach(nonWolves) { player in
                        Button {
                            appState.setWolfDecision(for: displayHole, partnerID: player.id)
                            showWolfPicker = false
                        } label: {
                            HStack {
                                Text("Partner with \(player.name)")
                                Spacer()
                                let state = appState.wolfHoleStates[displayHole]
                                if state?.partnerPlayerID == player.id && state?.isDecided == true {
                                    Image(systemName: "checkmark").foregroundStyle(.green)
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }

                Section {
                    Button {
                        appState.setWolfDecision(for: displayHole, partnerID: nil)
                        showWolfPicker = false
                    } label: {
                        HStack {
                            Text("Go Alone (Lone Wolf)")
                                .foregroundStyle(.orange)
                            Spacer()
                            let state = appState.wolfHoleStates[displayHole]
                            if state?.isLoneWolf == true && state?.isDecided == true {
                                Image(systemName: "checkmark").foregroundStyle(.green)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Wolf Decision — Hole \(displayHole)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showWolfPicker = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Hole result

    private func holeResult(for hole: Int) -> HoleResult? {
        switch appState.gameFormat {
        case .matchPlay:  return appState.matchHoleResult(for: hole)
        case .bestBall:   return appState.bestBallHoleResult(for: hole)
        default:          return nil
        }
    }

    @ViewBuilder
    private func holeResultView(_ result: HoleResult) -> some View {
        switch result {
        case .playerWins(let p):
            Text("\(p.name) wins the hole")
                .font(.subheadline).foregroundStyle(.primary)
                .padding(.horizontal)
        case .teamWins(let t):
            Text("Team \(appState.teamName(t)) wins the hole")
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

    // MARK: - Dictate All

    private var dictateAllSection: some View {
        VStack(spacing: 8) {
            Button { toggleDictateAll() } label: {
                Label(
                    isDictatingAll ? "Listening…" : "Dictate All Scores",
                    systemImage: isDictatingAll ? "waveform" : "mic.badge.plus"
                )
                .font(.subheadline)
                .padding(.horizontal, 20).padding(.vertical, 10)
                .background(isDictatingAll ? Color.orange.opacity(0.15) : Color.blue.opacity(0.1))
                .foregroundStyle(isDictatingAll ? .orange : .blue)
                .clipShape(Capsule())
            }
            .accessibilityIdentifier("round.dictateAllButton")

            if isDictatingAll, !speechRecognizer.lastHeardText.isEmpty {
                Text("\"\(speechRecognizer.lastHeardText)\"")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Actions

    private func toggleListening() {
        if speechRecognizer.state == .listening {
            isDictatingAll = false
            speechRecognizer.stopListening()
        } else {
            isDictatingAll = false
            let player = appState.players.first(where: { appState.score(for: $0, hole: displayHole) == nil })
            guard let player else { return }
            speechRecognizer.startListening(par: currentPar) { score in
                appState.recordScore(score, forHole: displayHole, player: player)
            }
        }
    }

    private func toggleDictateAll() {
        if speechRecognizer.state == .listening {
            isDictatingAll = false
            speechRecognizer.stopListening()
        } else {
            isDictatingAll = true
            speechRecognizer.lastHeardText = ""
            speechRecognizer.startListeningForMultiScore(
                players: appState.players,
                par: currentPar
            ) { [self] parsedScores in
                isDictatingAll = false
                for ps in parsedScores {
                    guard let player = appState.players.first(where: { $0.name == ps.playerName }) else { continue }
                    appState.recordScore(ps.strokes, forHole: displayHole, player: player)
                }
            }
        }
    }
}
