import SwiftUI
import SwiftData

private extension Color {
    static let emerald = Color(red: 46/255, green: 125/255, blue: 50/255)
}

struct HomeView: View {
    @Environment(AppRouter.self) private var router
    @Environment(AppState.self) private var appState

    @Query(sort: \RoundRecord.date, order: .reverse)
    private var allRounds: [RoundRecord]

    @Query private var allProfiles: [PlayerProfile]

    @State private var showAccountSheet = false

    private var recentRounds: [RoundRecord] { Array(allRounds.prefix(3)) }

    private var primaryProfile: PlayerProfile? {
        allProfiles.sorted {
            ($0.lastPlayed ?? .distantPast) > ($1.lastPlayed ?? .distantPast)
        }.first
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header

                if let profile = primaryProfile {
                    handicapCard(profile: profile)
                }

                startButton

                if !recentRounds.isEmpty {
                    recentRoundsSection
                }
            }
            .padding()
        }
        .navigationTitle("")
        .navigationBarHidden(true)
        .sheet(isPresented: $showAccountSheet) {
            AccountView()
        }
    }

    // MARK: - Header

    private var header: some View {
        ZStack {
            VStack(spacing: 8) {
                Image(systemName: "bird.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.emerald)
                Text("Birdie Buddy")
                    .font(.largeTitle).fontWeight(.bold)
            }
            HStack {
                Spacer()
                accountButton.padding(.top, 8)
            }
        }
        .padding(.top, 16)
    }

    @ViewBuilder
    private var accountButton: some View {
        if let session = appState.authSession {
            Button {
                showAccountSheet = true
            } label: {
                Circle()
                    .fill(Color.emerald.opacity(0.18))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(session.initials)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.emerald)
                    )
            }
            .accessibilityIdentifier("auth.accountAvatar")
        } else {
            Button("Sign In") {
                router.navigate(to: .signIn)
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(Color.emerald)
            .accessibilityIdentifier("auth.signInLink")
        }
    }

    // MARK: - Handicap card

    private func handicapCard(profile: PlayerProfile) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Handicap Index")
                    .font(.caption).foregroundStyle(.secondary)
                Text(profile.name)
                    .font(.subheadline).fontWeight(.medium)
            }
            Spacer()
            Text("\(profile.handicap)")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(Color.emerald)
        }
        .padding(20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.systemGray4), lineWidth: 0.5))
        .accessibilityIdentifier("home.handicapCard")
    }

    // MARK: - Start button

    private var startButton: some View {
        VStack(spacing: 10) {
            Button {
                router.navigate(to: .setup)
            } label: {
                Text("Start New Round")
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.emerald)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .accessibilityIdentifier("home.startRoundButton")

            HStack(spacing: 10) {
                Button {
                    if appState.isSignedIn { router.navigate(to: .roundLobby) }
                    else { router.navigate(to: .signIn) }
                } label: {
                    Text("Start Live Round")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color(.systemGray6))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .accessibilityIdentifier("home.startLiveRoundButton")

                Button {
                    if appState.isSignedIn { router.navigate(to: .joinRound) }
                    else { router.navigate(to: .signIn) }
                } label: {
                    Text("Join Round")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color(.systemGray6))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .accessibilityIdentifier("home.joinRoundButton")
            }

            if !allRounds.isEmpty {
                Button {
                    router.navigate(to: .stats)
                } label: {
                    Text("My Stats")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color(.systemGray6))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .accessibilityIdentifier("home.statsButton")
            }
        }
    }

    // MARK: - Recent rounds

    private var recentRoundsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Rounds")
                .font(.headline)

            VStack(spacing: 0) {
                ForEach(Array(recentRounds.enumerated()), id: \.element.id) { index, round in
                    roundRow(round)
                    if index < recentRounds.count - 1 {
                        Divider().padding(.leading)
                    }
                }
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.systemGray4), lineWidth: 0.5))
        }
    }

    private func roundRow(_ round: RoundRecord) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text(formatDate(round.date))
                    .font(.subheadline).fontWeight(.medium)
                Text(round.playerNames.joined(separator: " · "))
                    .font(.caption).foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                ForEach(round.playerNames, id: \.self) { name in
                    HStack(spacing: 6) {
                        if round.playerNames.count > 1 {
                            Text(name.components(separatedBy: " ").first ?? name)
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Text("\(round.totalScore(for: name))")
                            .font(.subheadline).fontWeight(.semibold)
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .accessibilityIdentifier("home.recentRoundRow")
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date)     { return "Today" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: date)
    }
}
