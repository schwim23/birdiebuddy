import SwiftUI
import SwiftData

private extension Color {
    static let emerald = Color(red: 46/255, green: 125/255, blue: 50/255)
}

struct HomeView: View {
    @Environment(AppRouter.self) private var router

    @Query(sort: \RoundRecord.date, order: .reverse)
    private var allRounds: [RoundRecord]

    @Query private var allProfiles: [PlayerProfile]

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
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "bird.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.emerald)
            Text("Birdie Buddy")
                .font(.largeTitle).fontWeight(.bold)
        }
        .padding(.top, 16)
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
