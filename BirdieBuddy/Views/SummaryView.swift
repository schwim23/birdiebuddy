import SwiftUI

struct SummaryView: View {
    @Environment(AppState.self) private var appState
    @Binding var navigateToRound: Bool

    var body: some View {
        VStack(spacing: 32) {
            Text("Round Complete!")
                .font(.largeTitle)
                .fontWeight(.bold)

            VStack(spacing: 8) {
                Text("Total Score")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text("\(appState.totalScore)")
                    .font(.system(size: 72, weight: .bold))
                    .accessibilityIdentifier("summary.totalScoreLabel")
            }
            .padding(32)
            .background(Color.green.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16))

            Button("Play Again") {
                appState.startRound()
                navigateToRound = true
            }
            .font(.title3)
            .padding(.horizontal, 40)
            .padding(.vertical, 14)
            .background(Color.green)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .navigationTitle("Summary")
        .navigationBarBackButtonHidden(true)
    }
}
