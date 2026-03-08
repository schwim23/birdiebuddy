
import SwiftUI
import SwiftData

struct TournamentListScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Tournament.startDate, order: .reverse) private var tournaments: [Tournament]
    @State private var showNewTournament = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                if tournaments.isEmpty {
                    VStack(spacing: 20) {
                        EmptyStateView(icon: "trophy.fill", message: "No tournaments yet.\nCreate one to run a multi-foursome or multi-day event!")
                        Button {
                            showNewTournament = true
                        } label: {
                            Label("Create Tournament", systemImage: "plus.circle.fill")
                                .primaryButtonStyle()
                        }
                        .padding(.horizontal, 40)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(tournaments) { tournament in
                                NavigationLink {
                                    TournamentHubScreen(tournament: tournament)
                                } label: {
                                    TournamentListCard(tournament: tournament)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Tournaments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showNewTournament = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showNewTournament) {
                NavigationStack {
                    TournamentSetupScreen()
                }
            }
        }
    }
}

private struct TournamentListCard: View {
    let tournament: Tournament

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(tournament.name)
                    .font(.subheadline.bold())
                    .foregroundStyle(Theme.textPrimary)
                Text("\(tournament.format.displayName) • \(tournament.players.count) players")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                HStack(spacing: 8) {
                    Text("\(tournament.startDate.shortFormatted) – \(tournament.endDate.shortFormatted)")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                HStack(spacing: 8) {
                    Text("Round \(tournament.completedRoundCount)/\(tournament.numberOfRounds)")
                        .font(.caption)
                        .foregroundStyle(Theme.primaryGreen)
                    Text("Code: \(tournament.inviteCode)")
                        .font(.caption.monospaced())
                        .foregroundStyle(Theme.accent)
                }
            }
            Spacer()
            VStack(spacing: 4) {
                StatusPill(status: tournament.status)
                Image(systemName: "chevron.right")
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .cardStyle()
    }
}

private struct StatusPill: View {
    let status: TournamentStatus

    private var label: String {
        switch status {
        case .setup: return "SETUP"
        case .active: return "LIVE"
        case .completed: return "DONE"
        case .cancelled: return "CANCELLED"
        }
    }

    private var color: Color {
        switch status {
        case .setup: return Theme.accent
        case .active: return Theme.primaryGreen
        case .completed: return Theme.bogey
        case .cancelled: return Theme.destructive
        }
    }

    var body: some View {
        Text(label)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}
