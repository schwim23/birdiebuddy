import SwiftUI

struct SummaryView: View {
    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router

    private var sortedPlayers: [Player] {
        appState.players.sorted { appState.totalScore(for: $0) < appState.totalScore(for: $1) }
    }

    var body: some View {
        VStack(spacing: 28) {
            Text("Round Complete!")
                .font(.largeTitle).fontWeight(.bold)

            // Leading score — always carries summary.totalScoreLabel for test compatibility
            if let leader = sortedPlayers.first {
                VStack(spacing: 4) {
                    Text(appState.players.count > 1 ? "Low Score" : "Total Score")
                        .font(.headline).foregroundStyle(.secondary)
                    Text("\(appState.totalScore(for: leader))")
                        .font(.system(size: 72, weight: .bold))
                        .accessibilityIdentifier("summary.totalScoreLabel")
                }
                .padding(24)
                .background(Color.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            // All player scores
            if appState.players.count > 1 {
                VStack(spacing: 4) {
                    ForEach(Array(sortedPlayers.enumerated()), id: \.element.id) { index, player in
                        HStack {
                            Text("\(index + 1). \(player.name)").font(.body)
                            Spacer()
                            Text("\(appState.totalScore(for: player))").font(.body).fontWeight(.semibold)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 6)
                        .accessibilityIdentifier("summary.playerRow")
                    }
                }
            }

            Button("New Round") {
                router.popToRoot()
            }
            .font(.title3)
            .padding(.horizontal, 40).padding(.vertical, 14)
            .background(Color.green)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .navigationTitle("Summary")
        .navigationBarBackButtonHidden(true)
    }
}
