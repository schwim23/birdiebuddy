
import SwiftUI
import SwiftData

struct TournamentHubScreen: View {
    @Environment(\.modelContext) private var modelContext
    var tournament: Tournament
    @State private var viewModel: TournamentViewModel
    @State private var selectedTab: HubTab = .leaderboard
    @State private var showCourseSearch = false
    @State private var courseForRound: Course?
    @State private var roundToStart: TournamentRound?

    enum HubTab: String, CaseIterable {
        case leaderboard = "Leaderboard"
        case rounds = "Rounds"
        case games = "Games"
        case teams = "Teams"
    }

    init(tournament: Tournament) {
        self.tournament = tournament
        _viewModel = State(initialValue: TournamentViewModel(tournament: tournament))
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(tournament.name)
                                .font(.title2.bold())
                                .foregroundStyle(Theme.textPrimary)
                            Text("\(tournament.format.displayName) • \(tournament.players.count) players")
                                .font(.subheadline)
                                .foregroundStyle(Theme.textSecondary)
                            Text("\(tournament.startDate.shortFormatted) – \(tournament.endDate.shortFormatted)")
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            HubStatusBadge(status: tournament.status)
                            Text("Code: \(tournament.inviteCode)")
                                .font(.caption.monospaced())
                                .foregroundStyle(Theme.primaryGreen)
                        }
                    }
                    .padding()
                    .background(Theme.cardBackground)

                    // Tabs
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(HubTab.allCases, id: \.self) { tab in
                                Button { selectedTab = tab } label: {
                                    Text(tab.rawValue)
                                        .font(.subheadline.bold())
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(selectedTab == tab ? Theme.primaryGreen : Theme.cardBackground)
                                        .foregroundStyle(selectedTab == tab ? .white : Theme.textPrimary)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // Content
                ScrollView {
                    VStack(spacing: 16) {
                        switch selectedTab {
                        case .leaderboard:
                            TournamentLeaderboardSection(entries: viewModel.engine.leaderboard)
                        case .rounds:
                            TournamentRoundsSection(
                                tournament: tournament,
                                viewModel: viewModel,
                                onSetPairings: { round in viewModel.startEditingPairings(for: round) },
                                onStartRound: { round in roundToStart = round; showCourseSearch = true },
                                onCompleteRound: { round in viewModel.completeRound(round, modelContext: modelContext) }
                            )
                        case .games:
                            TournamentGamesSection(gameStandings: viewModel.engine.gameStandings)
                        case .teams:
                            TournamentTeamsSection(
                                teamStandings: viewModel.engine.teamStandings,
                                players: tournament.players
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.refresh() }
        .sheet(isPresented: $viewModel.showPairingEditor) {
            NavigationStack {
                PairingEditorScreen(viewModel: viewModel, modelContext: modelContext)
            }
        }
        .sheet(isPresented: $showCourseSearch) {
            NavigationStack {
                CourseSearchScreen(selectedCourse: $courseForRound)
            }
        }
        .onChange(of: courseForRound) { _, course in
            if let course = course, let round = roundToStart {
                viewModel.startRound(round, course: course, modelContext: modelContext)
                viewModel.refresh()
                courseForRound = nil
                roundToStart = nil
            }
        }
    }
}

// MARK: - Status Badge

private struct HubStatusBadge: View {
    let status: TournamentStatus

    private var label: String {
        switch status {
        case .setup: return "SETUP"
        case .active: return "LIVE"
        case .completed: return "COMPLETE"
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

// MARK: - Leaderboard Section

private struct TournamentLeaderboardSection: View {
    let entries: [TournamentLeaderboardEntry]

    var body: some View {
        VStack(spacing: 12) {
            if entries.isEmpty {
                EmptyStateView(icon: "trophy", message: "No scores yet. Start a round to see the leaderboard!")
            } else {
                HStack {
                    Text("#").frame(width: 24)
                    Text("Player").frame(maxWidth: .infinity, alignment: .leading)
                    Text("Rds").frame(width: 30)
                    Text("Gross").frame(width: 45)
                    Text("Net").frame(width: 45)
                    Text("Pts").frame(width: 38)
                }
                .font(.caption.bold())
                .foregroundStyle(Theme.textSecondary)

                ForEach(entries) { entry in
                    VStack(spacing: 4) {
                        HStack {
                            Text("\(entry.position)")
                                .font(.headline)
                                .foregroundStyle(entry.position <= 3 ? Theme.accent : Theme.textSecondary)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.playerName)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(Theme.textPrimary)
                                if !entry.teamTag.isEmpty {
                                    Text(entry.teamTag)
                                        .font(.caption2)
                                        .foregroundStyle(Theme.primaryGreen)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            Text("\(entry.roundsPlayed)")
                                .frame(width: 30)
                            Text("\(entry.totalGrossScore)")
                                .frame(width: 45)
                            Text("\(entry.totalNetScore)")
                                .font(.subheadline.bold())
                                .frame(width: 45)
                            Text(String(format: "%.0f", entry.gamePoints))
                                .frame(width: 38)
                        }
                        .font(.subheadline)
                        .foregroundStyle(Theme.textPrimary)

                        // Round details
                        if !entry.roundDetails.isEmpty {
                            ForEach(entry.roundDetails) { detail in
                                HStack {
                                    Text("  R\(detail.roundNumber)")
                                        .font(.caption2)
                                        .foregroundStyle(Theme.textSecondary)
                                    Text(detail.courseName)
                                        .font(.caption2)
                                        .foregroundStyle(Theme.textSecondary)
                                        .lineLimit(1)
                                    Spacer()
                                    Text("G:\(detail.grossScore) N:\(detail.netScore)")
                                        .font(.caption2.monospaced())
                                        .foregroundStyle(Theme.textSecondary)
                                }
                                .padding(.leading, 32)
                            }
                        }
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .background(entry.position <= 3 ? Theme.lightGreen.opacity(0.3) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
}

// MARK: - Rounds Section

private struct TournamentRoundsSection: View {
    let tournament: Tournament
    let viewModel: TournamentViewModel
    let onSetPairings: (TournamentRound) -> Void
    let onStartRound: (TournamentRound) -> Void
    let onCompleteRound: (TournamentRound) -> Void

    var body: some View {
        VStack(spacing: 16) {
            ForEach(tournament.sortedRounds) { tRound in
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Round \(tRound.roundNumber)")
                                .font(.headline)
                                .foregroundStyle(Theme.textPrimary)
                            if !tRound.courseName.isEmpty {
                                Text(tRound.courseName)
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            Text(tRound.date.shortFormatted)
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        Spacer()
                        RoundBadge(status: tRound.status)
                    }

                    if tRound.foursomes.isEmpty {
                        Button { onSetPairings(tRound) } label: {
                            Label("Set Pairings", systemImage: "person.3.sequence.fill")
                                .secondaryButtonStyle()
                        }
                    } else {
                        ForEach(tRound.sortedFoursomes) { foursome in
                            FoursomeRow(foursome: foursome)
                        }

                        HStack(spacing: 12) {
                            if tRound.status == .upcoming {
                                Button { onSetPairings(tRound) } label: {
                                    Label("Edit Pairings", systemImage: "pencil")
                                        .font(.caption.bold())
                                        .foregroundStyle(Theme.primaryGreen)
                                }
                                Spacer()
                                Button { onStartRound(tRound) } label: {
                                    Label("Start Round", systemImage: "play.fill")
                                        .font(.caption.bold())
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Theme.primaryGreen)
                                        .clipShape(Capsule())
                                }
                            }

                            if tRound.status == .active && tRound.allFoursomesComplete {
                                Spacer()
                                Button { onCompleteRound(tRound) } label: {
                                    Label("Complete Round", systemImage: "checkmark.circle.fill")
                                        .font(.caption.bold())
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Theme.accent)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }
                .cardStyle()
            }
        }
    }
}

private struct RoundBadge: View {
    let status: TournamentRoundStatus

    var body: some View {
        Text(label)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private var label: String {
        switch status {
        case .upcoming: return "UPCOMING"
        case .active: return "LIVE"
        case .completed: return "DONE"
        }
    }

    private var color: Color {
        switch status {
        case .upcoming: return Theme.textSecondary
        case .active: return Theme.primaryGreen
        case .completed: return Theme.bogey
        }
    }
}

private struct FoursomeRow: View {
    let foursome: Foursome

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(foursome.groupName)
                    .font(.subheadline.bold())
                    .foregroundStyle(Theme.primaryGreen)
                Spacer()
                if foursome.isComplete {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.primaryGreen)
                        .font(.caption)
                } else if foursome.golfRound != nil {
                    Text("In Progress")
                        .font(.caption2)
                        .foregroundStyle(Theme.accent)
                }
            }

            ForEach(foursome.playerNames, id: \.self) { name in
                HStack(spacing: 6) {
                    Circle().fill(Theme.secondaryGreen.opacity(0.4)).frame(width: 6, height: 6)
                    Text(name).font(.caption).foregroundStyle(Theme.textPrimary)
                }
            }

            if let round = foursome.golfRound {
                NavigationLink {
                    ScorecardScreen(round: round)
                } label: {
                    HStack {
                        Text("Hole \(round.completedHoles)/\(round.holeCount)")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                        Spacer()
                        Text("Open Scorecard →")
                            .font(.caption.bold())
                            .foregroundStyle(Theme.primaryGreen)
                    }
                }
            }
        }
        .padding(10)
        .background(Theme.lightGreen.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Games Section

private struct TournamentGamesSection: View {
    let gameStandings: [GameFormatStanding]

    var body: some View {
        VStack(spacing: 16) {
            if gameStandings.isEmpty {
                EmptyStateView(icon: "trophy", message: "Game results will appear here after rounds are scored.")
            }

            ForEach(gameStandings) { gs in
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        if let format = GameFormat(rawValue: gs.formatRaw) {
                            Image(systemName: format.iconName)
                        }
                        Text(gs.formatDisplayName)
                            .font(.headline)
                    }
                    .foregroundStyle(Theme.textPrimary)

                    HStack {
                        Text("Player").frame(maxWidth: .infinity, alignment: .leading)
                        Text("Total Pts").frame(width: 70)
                    }
                    .font(.caption.bold())
                    .foregroundStyle(Theme.textSecondary)

                    ForEach(Array(gs.playerScores.enumerated()), id: \.element.id) { index, ps in
                        HStack {
                            Text("\(index + 1)")
                                .font(.subheadline.bold())
                                .foregroundStyle(index < 3 ? Theme.accent : Theme.textSecondary)
                                .frame(width: 20)
                            Text(ps.playerName)
                                .font(.subheadline)
                                .foregroundStyle(Theme.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(String(format: "%.0f", ps.totalPoints))
                                .font(.subheadline.bold())
                                .foregroundStyle(Theme.primaryGreen)
                                .frame(width: 70)
                        }

                        if !ps.roundPoints.isEmpty {
                            HStack(spacing: 8) {
                                ForEach(ps.roundPoints) { rp in
                                    Text("R\(rp.roundNumber): \(String(format: "%.0f", rp.points))")
                                        .font(.caption2)
                                        .foregroundStyle(Theme.textSecondary)
                                }
                            }
                            .padding(.leading, 28)
                        }
                    }
                }
                .cardStyle()
            }
        }
    }
}

// MARK: - Teams Section

private struct TournamentTeamsSection: View {
    let teamStandings: [TeamStanding]
    let players: [TournamentPlayer]

    var body: some View {
        VStack(spacing: 16) {
            if teamStandings.isEmpty {
                // Show all players grouped by team
                let grouped = Dictionary(grouping: players) { $0.teamTag.isEmpty ? "No Team" : $0.teamTag }
                ForEach(Array(grouped.keys.sorted()), id: \.self) { team in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(team)
                            .font(.headline)
                            .foregroundStyle(Theme.primaryGreen)
                        ForEach(grouped[team] ?? [], id: \.id) { p in
                            HStack {
                                Text(p.displayName)
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.textPrimary)
                                Spacer()
                                Text("HCP: \(String(format: "%.1f", p.handicapIndex))")
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
                    }
                    .cardStyle()
                }
            } else {
                ForEach(teamStandings) { team in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("\(team.position)")
                                .font(.title3.bold())
                                .foregroundStyle(team.position <= 2 ? Theme.accent : Theme.textSecondary)
                                .frame(width: 28)
                            Text(team.teamTag)
                                .font(.headline)
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Net: \(team.totalNetScore)")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(Theme.primaryGreen)
                                Text("Pts: \(String(format: "%.0f", team.totalGamePoints))")
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }

                        ForEach(team.playerNames, id: \.self) { name in
                            HStack(spacing: 6) {
                                Circle().fill(Theme.secondaryGreen).frame(width: 6, height: 6)
                                Text(name).font(.caption).foregroundStyle(Theme.textPrimary)
                            }
                        }
                    }
                    .cardStyle()
                }
            }
        }
    }
}
