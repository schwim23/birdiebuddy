import SwiftUI
import SwiftData

struct SummaryView: View {
    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router
    @Environment(\.modelContext) private var modelContext

    @State private var roundSaved = false

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
        .onAppear {
            saveRoundIfNeeded()
        }
    }

    private func saveRoundIfNeeded() {
        guard !roundSaved, !appState.players.isEmpty else { return }
        roundSaved = true
        let record = RoundRecord(
            date: Date(),
            players: appState.players,
            scores: appState.scores
        )
        modelContext.insert(record)

        // Mark each player's lastPlayed date
        // (fetched profiles are available only if a @Query is present;
        //  we update via a separate fetch to avoid adding @Query here)
        let ids = appState.players.map { $0.id }
        let descriptor = FetchDescriptor<PlayerProfile>(
            predicate: #Predicate { ids.contains($0.id) }
        )
        if let profiles = try? modelContext.fetch(descriptor) {
            for profile in profiles {
                profile.lastPlayed = Date()
            }
        }
    }
}
