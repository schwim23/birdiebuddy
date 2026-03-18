import SwiftUI

struct RoundView: View {
    @Environment(AppState.self) private var appState
    @Binding var navigateToRound: Bool
    @State private var navigateToSummary = false
    @State private var speechRecognizer = SpeechRecognizer()
    @State private var displayHole: Int = 1

    private let par = 4
    private let scoreRange = 1...9

    private var isOnLeadingHole: Bool { displayHole == appState.currentHole }
    private var canGoBack: Bool { displayHole > 1 }
    private var canGoForward: Bool { displayHole < appState.currentHole }

    var body: some View {
        VStack(spacing: 24) {
            // Hole header with navigation arrows
            HStack(spacing: 24) {
                Button {
                    displayHole -= 1
                    speechRecognizer.stopListening()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .frame(width: 44, height: 44)
                }
                .disabled(!canGoBack)
                .accessibilityIdentifier("round.prevHoleButton")

                VStack(spacing: 4) {
                    Text("Hole \(displayHole)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .accessibilityIdentifier("round.holeLabel")

                    Text("Par \(par)")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("round.parLabel")
                }

                Button {
                    displayHole += 1
                    speechRecognizer.stopListening()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .frame(width: 44, height: 44)
                }
                .disabled(!canGoForward)
                .accessibilityIdentifier("round.nextHoleButton")
            }
            .padding(.top, 40)

            // Score indicator — shows existing score; tinted when reviewing a past hole
            if let existingScore = appState.scores[displayHole] {
                Text("Score: \(existingScore)")
                    .font(.title3)
                    .foregroundStyle(isOnLeadingHole ? .primary : .secondary)
                    .accessibilityIdentifier("round.currentScoreLabel")
            }

            Spacer()

            Text(isOnLeadingHole ? "Select your score" : "Update score for hole \(displayHole)")
                .font(.headline)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                ForEach(scoreRange, id: \.self) { score in
                    let isSelected = appState.scores[displayHole] == score
                    Button("\(score)") {
                        recordScore(score)
                    }
                    .font(.title2)
                    .frame(width: 70, height: 70)
                    .background(isSelected ? Color.blue.opacity(0.5) : Color.blue.opacity(0.15))
                    .foregroundStyle(isSelected ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .accessibilityIdentifier("round.scoreButton.\(score)")
                }
            }
            .padding(.horizontal)

            // Mic button — only shown when on the leading hole
            if isOnLeadingHole && speechRecognizer.state != .unavailable {
                VStack(spacing: 12) {
                    Button {
                        toggleListening()
                    } label: {
                        Label(
                            speechRecognizer.state == .listening ? "Listening…" : "Say Your Score",
                            systemImage: speechRecognizer.state == .listening ? "waveform" : "mic"
                        )
                        .font(.headline)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(speechRecognizer.state == .listening ? Color.red.opacity(0.15) : Color.green.opacity(0.15))
                        .foregroundStyle(speechRecognizer.state == .listening ? .red : .green)
                        .clipShape(Capsule())
                    }
                    .accessibilityIdentifier("round.micButton")

                    if !speechRecognizer.lastHeardText.isEmpty {
                        Text("Heard: \"\(speechRecognizer.lastHeardText)\"")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("round.voiceFeedbackLabel")
                    }
                }
            }

            Spacer()
        }
        .navigationTitle("Round in Progress")
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $navigateToSummary) {
            SummaryView(navigateToSummary: $navigateToSummary)
        }
        .onAppear {
            displayHole = appState.currentHole
        }
        .task {
            _ = await speechRecognizer.requestPermissions()
        }
        .onDisappear {
            speechRecognizer.stopListening()
        }
    }

    private func recordScore(_ score: Int) {
        let wasLeadingHole = isOnLeadingHole
        speechRecognizer.stopListening()
        appState.recordScore(score, forHole: displayHole)
        if appState.isRoundFinished {
            navigateToSummary = true
        } else if wasLeadingHole {
            // Advance display to the new leading hole
            displayHole = appState.currentHole
        }
        // Re-edits: stay on the same hole so the user can see the updated score
    }

    private func toggleListening() {
        if speechRecognizer.state == .listening {
            speechRecognizer.stopListening()
        } else {
            speechRecognizer.startListening(par: par) { score in
                recordScore(score)
            }
        }
    }
}
