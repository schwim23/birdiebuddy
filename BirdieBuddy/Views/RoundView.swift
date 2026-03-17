import SwiftUI

struct RoundView: View {
    @Environment(AppState.self) private var appState
    @Binding var navigateToRound: Bool
    @State private var navigateToSummary = false
    @State private var speechRecognizer = SpeechRecognizer()

    private let par = 4
    private let scoreRange = 1...9

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Hole \(appState.currentHole)")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .accessibilityIdentifier("round.holeLabel")

                Text("Par \(par)")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("round.parLabel")
            }
            .padding(.top, 40)

            if let currentScore = appState.scores[appState.currentHole] {
                Text("Score: \(currentScore)")
                    .font(.title3)
                    .accessibilityIdentifier("round.currentScoreLabel")
            }

            Spacer()

            Text("Select your score")
                .font(.headline)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                ForEach(scoreRange, id: \.self) { score in
                    Button("\(score)") {
                        recordScore(score)
                    }
                    .font(.title2)
                    .frame(width: 70, height: 70)
                    .background(Color.blue.opacity(0.15))
                    .foregroundStyle(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .accessibilityIdentifier("round.scoreButton.\(score)")
                }
            }
            .padding(.horizontal)

            if speechRecognizer.isAvailable || speechRecognizer.state == .idle {
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
        .task {
            _ = await speechRecognizer.requestPermissions()
        }
        .onDisappear {
            speechRecognizer.stopListening()
        }
    }

    private func recordScore(_ score: Int) {
        speechRecognizer.stopListening()
        appState.recordScore(score, forHole: appState.currentHole)
        if appState.isRoundFinished {
            navigateToSummary = true
        }
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
