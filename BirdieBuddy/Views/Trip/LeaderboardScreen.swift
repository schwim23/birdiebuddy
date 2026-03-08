
import SwiftUI

struct LeaderboardScreen: View {
    let entries: [TripLeaderboardEntry]

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 12) {
                    if entries.isEmpty {
                        EmptyStateView(icon: "trophy", message: "No scores yet.")
                    } else {
                        HStack {
                            Text("#").frame(width: 24)
                            Text("Player").frame(maxWidth: .infinity, alignment: .leading)
                            Text("Rds").frame(width: 36)
                            Text("Net").frame(width: 50)
                        }
                        .font(.caption.bold())
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.horizontal)

                        ForEach(entries) { entry in
                            HStack {
                                Text("\(entry.position)")
                                    .font(.headline)
                                    .foregroundStyle(entry.position <= 3 ? Theme.accent : Theme.textSecondary)
                                    .frame(width: 24)
                                Text(entry.playerName)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(Theme.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("\(entry.roundsPlayed)")
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.textSecondary)
                                    .frame(width: 36)
                                Text("\(entry.totalNetScore)")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(Theme.primaryGreen)
                                    .frame(width: 50)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(entry.position <= 3 ? Theme.lightGreen.opacity(0.3) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .padding(.horizontal, 8)
                        }
                    }
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Leaderboard")
        .navigationBarTitleDisplayMode(.inline)
    }
}
