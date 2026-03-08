
import SwiftUI
import SwiftData

struct HomeScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @State private var viewModel = HomeViewModel()
    @State private var showNewRound = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Welcome back,").font(.subheadline).foregroundStyle(Theme.textSecondary)
                                Text(appState.currentUser?.displayName ?? "Golfer").font(.title2.bold()).foregroundStyle(Theme.textPrimary)
                            }
                            Spacer()
                            Image(systemName: "figure.golf").font(.system(size: 40)).foregroundStyle(Theme.primaryGreen)
                        }.padding(.horizontal)

                        Button { showNewRound = true } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill").font(.title2)
                                VStack(alignment: .leading) {
                                    Text("New Round").font(.headline)
                                    Text("Start scoring a round").font(.caption).opacity(0.8)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .foregroundStyle(.white).padding()
                            .background(Theme.primaryGreen)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
                        }.padding(.horizontal)

                        let active = viewModel.recentRounds.filter { $0.roundStatus == .active }
                        if !active.isEmpty {
                            SectionLabel(title: "Active Rounds")
                            ForEach(active) { round in
                                NavigationLink { ScorecardScreen(round: round) } label: {
                                    RoundCard(round: round, isActive: true)
                                }.padding(.horizontal)
                            }
                        }

                        if !viewModel.tournaments.isEmpty {
                            SectionLabel(title: "Tournaments")
                            ForEach(viewModel.tournaments) { t in
                                NavigationLink { TournamentHubScreen(tournament: t) } label: {
                                    TournamentCard(tournament: t)
                                }.padding(.horizontal)
                            }
                        }

                        let completed = viewModel.recentRounds.filter { $0.roundStatus == .completed }
                        if !completed.isEmpty {
                            SectionLabel(title: "Recent Rounds")
                            ForEach(completed.prefix(5)) { round in
                                NavigationLink { RoundSummaryScreen(round: round) } label: {
                                    RoundCard(round: round, isActive: false)
                                }.padding(.horizontal)
                            }
                        }

                        if viewModel.recentRounds.isEmpty && viewModel.tournaments.isEmpty {
                            EmptyStateView(icon: "flag.fill", message: "No rounds yet. Start your first round!")
                        }
                        Spacer(minLength: 40)
                    }.padding(.top)
                }
            }
            .navigationTitle("BirdieBuddy")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showNewRound) { NavigationStack { NewRoundSetupScreen() } }
            .onAppear { viewModel.loadData(modelContext: modelContext) }
        }
    }
}

private struct SectionLabel: View {
    let title: String
    var body: some View {
        Text(title).font(.headline).foregroundStyle(Theme.textPrimary).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal)
    }
}

private struct RoundCard: View {
    let round: GolfRound
    let isActive: Bool
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(round.course?.name ?? "Unknown").font(.subheadline.bold()).foregroundStyle(Theme.textPrimary)
                Text("\(round.players.count) players • \(round.holeCount) holes").font(.caption).foregroundStyle(Theme.textSecondary)
                if isActive { Text("Hole \(round.completedHoles + 1)").font(.caption).foregroundStyle(Theme.primaryGreen) }
                else { Text(round.date.shortFormatted).font(.caption).foregroundStyle(Theme.textSecondary) }
            }
            Spacer()
            if isActive { Circle().fill(Theme.primaryGreen).frame(width: 8, height: 8) }
            Image(systemName: "chevron.right").foregroundStyle(Theme.textSecondary)
        }.cardStyle()
    }
}

private struct TournamentCard: View {
    let tournament: Tournament
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(tournament.name).font(.subheadline.bold()).foregroundStyle(Theme.textPrimary)
                Text("\(tournament.format.displayName) • \(tournament.players.count) players").font(.caption).foregroundStyle(Theme.textSecondary)
                Text("Round \(tournament.completedRoundCount + 1) of \(tournament.numberOfRounds)").font(.caption).foregroundStyle(Theme.primaryGreen)
            }
            Spacer()
            Image(systemName: "trophy.fill").foregroundStyle(Theme.accent)
            Image(systemName: "chevron.right").foregroundStyle(Theme.textSecondary)
        }.cardStyle()
    }
}
