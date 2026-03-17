import SwiftUI

struct RoundView: View {
    @Environment(AppState.self) private var appState
    @Binding var navigateToRound: Bool
    @State private var navigateToSummary = false

    private let par = 4
    private let scoreRange = 3...10

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
                        appState.recordScore(score, forHole: appState.currentHole)
                        if appState.isRoundFinished {
                            navigateToSummary = true
                        }
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

            Spacer()
        }
        .navigationTitle("Round in Progress")
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $navigateToSummary) {
            SummaryView(navigateToRound: $navigateToRound)
        }
    }
}
