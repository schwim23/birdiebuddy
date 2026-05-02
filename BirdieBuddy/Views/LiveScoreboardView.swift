import SwiftUI

/// Read-only scoreboard for a collaborative round. Pulls SessionPlayer +
/// ScoreEntry records from CloudKit on appear and on a 5-second tick while
/// visible. Single-group for now (013 Phase 1); will expand to multi-group
/// when 013 grows multi-group support.
struct LiveScoreboardView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var players: [SessionPlayerDTO] = []
    @State private var scoresByPlayer: [String: [Int: Int]] = [:]   // name → hole → strokes
    @State private var lastRefresh: Date?
    @State private var isRefreshing = false
    @State private var error: String?

    private let pollInterval: TimeInterval = 5

    var body: some View {
        NavigationStack {
            ScrollView([.horizontal, .vertical]) {
                if players.isEmpty {
                    emptyState
                } else {
                    scoreGrid
                }
            }
            .padding()
            .navigationTitle("Live Scoreboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .bottomBar) {
                    HStack {
                        if isRefreshing {
                            ProgressView()
                        } else if let lastRefresh {
                            Text("Updated \(timeAgo(lastRefresh))")
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Refresh") { Task { await refresh() } }
                            .font(.caption.weight(.medium))
                            .accessibilityIdentifier("liveScoreboard.refreshButton")
                    }
                }
            }
            .task { await pollLoop() }
        }
        .accessibilityIdentifier("liveScoreboard.root")
    }

    // MARK: - Polling

    private func pollLoop() async {
        await refresh()
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
            if Task.isCancelled { break }
            await refresh()
        }
    }

    private func refresh() async {
        guard let live = appState.liveSession else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            async let p = appState.cloudKit.fetchPlayers(in: live.roundGroupID)
            async let s = appState.cloudKit.fetchScores(in: live.roundGroupID)
            let (newPlayers, newScores) = try await (p, s)

            var merged: [String: [Int: Int]] = [:]
            for entry in newScores {
                merged[entry.playerName, default: [:]][entry.hole] = entry.strokes
            }
            players = newPlayers
            scoresByPlayer = merged
            lastRefresh = Date()
            error = nil
        } catch {
            self.error = "Could not refresh."
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.3").font(.largeTitle).foregroundStyle(.secondary)
            Text("Waiting for scores…").foregroundStyle(.secondary)
            if let error {
                Text(error).font(.caption).foregroundStyle(.red)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 220)
    }

    private var scoreGrid: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerRow
            Divider()
            ForEach(players) { player in
                scoreRow(for: player)
                    .accessibilityIdentifier("liveScoreboard.row.\(player.name)")
                Divider()
            }
        }
    }

    private var headerRow: some View {
        HStack(spacing: 4) {
            Text("Player")
                .frame(width: 96, alignment: .leading)
                .font(.caption.weight(.semibold))
            ForEach(1...18, id: \.self) { hole in
                Text("\(hole)")
                    .frame(width: 28, alignment: .center)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Text("Tot")
                .frame(width: 40, alignment: .trailing)
                .font(.caption.weight(.semibold))
        }
        .padding(.vertical, 6)
    }

    private func scoreRow(for player: SessionPlayerDTO) -> some View {
        let holes = scoresByPlayer[player.name] ?? [:]
        let total = holes.values.reduce(0, +)
        return HStack(spacing: 4) {
            Text(player.name)
                .frame(width: 96, alignment: .leading)
                .font(.subheadline)
                .lineLimit(1)
            ForEach(1...18, id: \.self) { hole in
                if let s = holes[hole] {
                    Text("\(s)").frame(width: 28).font(.subheadline.monospacedDigit())
                } else {
                    Text("–").frame(width: 28).foregroundStyle(.tertiary)
                }
            }
            Text(total > 0 ? "\(total)" : "–")
                .frame(width: 40, alignment: .trailing)
                .font(.subheadline.weight(.semibold).monospacedDigit())
        }
        .padding(.vertical, 6)
    }

    private func timeAgo(_ d: Date) -> String {
        let secs = Int(Date().timeIntervalSince(d))
        if secs < 5 { return "just now" }
        if secs < 60 { return "\(secs)s ago" }
        return "\(secs / 60)m ago"
    }
}
