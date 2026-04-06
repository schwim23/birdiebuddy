import SwiftUI
import SwiftData

struct StatsView: View {
    @Query(sort: \RoundRecord.date, order: .reverse) private var allRounds: [RoundRecord]
    @Query(sort: \PlayerProfile.name) private var profiles: [PlayerProfile]

    @State private var selectedName: String? = nil

    private var playerNames: [String] {
        var seen = Set<String>()
        return allRounds.flatMap { $0.playerNames }.filter { seen.insert($0).inserted }.sorted()
    }

    private var effectiveName: String {
        if let name = selectedName, playerNames.contains(name) { return name }
        // Default to most-recently-played profile, or first alphabetically
        let recent = profiles.sorted { ($0.lastPlayed ?? .distantPast) > ($1.lastPlayed ?? .distantPast) }.first?.name
        return recent ?? playerNames.first ?? ""
    }

    private var playerRounds: [RoundRecord] {
        allRounds.filter { $0.playerNames.contains(effectiveName) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Player picker
                if playerNames.count > 1 {
                    Picker("Player", selection: Binding(
                        get: { effectiveName },
                        set: { selectedName = $0 }
                    )) {
                        ForEach(playerNames, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu)
                    .padding(.horizontal)
                    .accessibilityIdentifier("stats.playerPicker")
                }

                if playerRounds.isEmpty {
                    ContentUnavailableView(
                        "No Rounds Yet",
                        systemImage: "flag.slash",
                        description: Text("Complete a round to see your stats here.")
                    )
                    .padding(.top, 60)
                } else {
                    overviewCard
                    breakdownSection
                    recentRoundsSection
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Stats")
    }

    // MARK: - Overview card

    private var overviewCard: some View {
        let totals = playerRounds.map { $0.totalScore(for: effectiveName) }.filter { $0 > 0 }
        let avg   = totals.isEmpty ? 0 : totals.reduce(0, +) / totals.count
        let best  = totals.min() ?? 0
        let worst = totals.max() ?? 0

        return VStack(spacing: 0) {
            HStack(spacing: 0) {
                statCell(value: "\(playerRounds.count)", label: "Rounds", id: "stats.roundsCount")
                Divider().frame(height: 56)
                statCell(value: avg > 0 ? "\(avg)" : "—", label: "Avg Score", id: "stats.averageScore")
            }
            Divider()
            HStack(spacing: 0) {
                statCell(value: best > 0 ? "\(best)" : "—", label: "Best Round", id: "stats.bestRound")
                Divider().frame(height: 56)
                statCell(value: worst > 0 ? "\(worst)" : "—", label: "Worst Round", id: "stats.worstRound")
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.systemGray4), lineWidth: 0.5))
        .padding(.horizontal)
        .accessibilityIdentifier("stats.overviewCard")
    }

    private func statCell(value: String, label: String, id: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title.weight(.bold))
                .foregroundStyle(Color(red: 46/255, green: 125/255, blue: 50/255))
            Text(label)
                .font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .accessibilityIdentifier(id)
    }

    // MARK: - Scoring breakdown

    private var breakdownSection: some View {
        let profile = aggregateProfile(for: effectiveName)
        guard profile.holesPlayed > 0 else { return AnyView(EmptyView()) }

        return AnyView(
            VStack(alignment: .leading, spacing: 12) {
                Text("Scoring Breakdown")
                    .font(.headline)
                    .padding(.horizontal)

                PlayerBreakdownRow(profile: profile, showName: false)
                    .padding(.horizontal)
                    .accessibilityIdentifier("stats.breakdownBar")

                breakdownLegend
                    .padding(.horizontal)
            }
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.systemGray4), lineWidth: 0.5))
            .padding(.horizontal)
        )
    }

    private var breakdownLegend: some View {
        HStack(spacing: 12) {
            ForEach(ScoreCategory.allCases, id: \.self) { cat in
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 3).fill(cat.color).frame(width: 12, height: 12)
                    Text(cat.label).font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Recent rounds

    private var recentRoundsSection: some View {
        let recent = Array(playerRounds.prefix(10))
        return VStack(alignment: .leading, spacing: 12) {
            Text("Recent Rounds")
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 0) {
                ForEach(Array(recent.enumerated()), id: \.element.id) { index, round in
                    recentRoundRow(round)
                    if index < recent.count - 1 { Divider().padding(.leading) }
                }
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.systemGray4), lineWidth: 0.5))
            .padding(.horizontal)
        }
    }

    private func recentRoundRow(_ round: RoundRecord) -> some View {
        let total = round.totalScore(for: effectiveName)
        let par   = round.totalPar(for: effectiveName)
        let diff  = total - par
        let diffText = diff == 0 ? "E" : (diff > 0 ? "+\(diff)" : "\(diff)")
        let diffColor: Color = diff < 0 ? Color(red: 46/255, green: 125/255, blue: 50/255)
                              : diff > 0 ? .red : .primary

        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(formatDate(round.date))
                    .font(.subheadline).fontWeight(.medium)
                Text(round.playerNames.filter { $0 != effectiveName }.joined(separator: " · "))
                    .font(.caption).foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            HStack(spacing: 8) {
                Text(diffText).font(.subheadline).foregroundStyle(diffColor).fontWeight(.semibold)
                Text("\(total)").font(.subheadline).fontWeight(.bold)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .accessibilityIdentifier("stats.recentRoundRow")
    }

    // MARK: - Helpers

    /// Aggregates scoring breakdown across all rounds for the given player.
    private func aggregateProfile(for name: String) -> ScoringProfile {
        var totalScores: [UUID: [Int: Int]] = [:]
        var totalPar: [Int: Int] = [:]
        var holeOffset = 0
        let dummyID = UUID()

        for round in playerRounds {
            let par = round.roundPar
            let entries = round.scoreEntries.filter { $0.playerName == name }
            for entry in entries {
                let syntheticHole = (holeOffset + entry.hole - 1) % 10000 + 1
                totalScores[dummyID, default: [:]][syntheticHole] = entry.strokes
                totalPar[syntheticHole] = par[entry.hole] ?? 4
            }
            holeOffset += 18
        }

        let dummyPlayer = Player(id: dummyID, name: name, handicap: 0)
        return ScoringProfile(player: dummyPlayer, scores: totalScores, roundPar: totalPar)
    }

    private func formatDate(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date)     { return "Today" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f.string(from: date)
    }
}
