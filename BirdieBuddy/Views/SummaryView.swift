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

            // Match play result
            if appState.gameFormat == .matchPlay {
                Text(appState.matchStatusText)
                    .font(.title2).fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24).padding(.vertical, 14)
                    .background(Color.green.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .accessibilityIdentifier("summary.matchResultLabel")
            }

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

            // Scoring breakdown chart
            scoringBreakdown

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

    // MARK: - Scoring Breakdown

    private var scoringBreakdown: some View {
        let profiles = appState.players.map { ScoringProfile(player: $0, scores: appState.scores, roundPar: appState.roundPar) }
        let anyHoles = profiles.contains { $0.holesPlayed > 0 }

        return Group {
            if anyHoles {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Scoring Breakdown")
                        .font(.headline)
                        .padding(.horizontal, 24)

                    VStack(spacing: 10) {
                        ForEach(appState.players, id: \.id) { player in
                            if let profile = profiles.first(where: { $0.player.id == player.id }),
                               profile.holesPlayed > 0 {
                                PlayerBreakdownRow(profile: profile, showName: appState.players.count > 1)
                            }
                        }
                    }

                    breakdownLegend
                }
                .padding(.vertical, 16)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.systemGray4), lineWidth: 0.5))
                .padding(.horizontal, 24)
                .accessibilityIdentifier("summary.scoringBreakdown")
            }
        }
    }

    private var breakdownLegend: some View {
        HStack(spacing: 12) {
            ForEach(ScoreCategory.allCases, id: \.self) { cat in
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(cat.color)
                        .frame(width: 12, height: 12)
                    Text(cat.label)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Persistence

    private func saveRoundIfNeeded() {
        guard !roundSaved, !appState.players.isEmpty else { return }
        roundSaved = true
        let record = RoundRecord(
            date: Date(),
            players: appState.players,
            scores: appState.scores,
            roundPar: appState.roundPar
        )
        modelContext.insert(record)

        // Mark each player's lastPlayed date
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

// MARK: - Score Category

enum ScoreCategory: CaseIterable {
    case eagle, birdie, par, bogey, double

    var label: String {
        switch self {
        case .eagle:  return "Eagle+"
        case .birdie: return "Birdie"
        case .par:    return "Par"
        case .bogey:  return "Bogey"
        case .double: return "Dbl+"
        }
    }

    var color: Color {
        switch self {
        case .eagle:  return Color(red: 249/255, green: 168/255, blue: 37/255)  // Sand Trap Gold
        case .birdie: return Color(red: 46/255,  green: 125/255, blue: 50/255)  // Emerald Green
        case .par:    return Color(red: 117/255, green: 117/255, blue: 117/255) // Fairway Gray
        case .bogey:  return Color(red: 198/255, green: 40/255,  blue: 40/255)  // Rough Red
        case .double: return Color(red: 139/255, green: 0/255,   blue: 0/255)   // Dark Red
        }
    }

    static func category(for score: Int, par: Int) -> ScoreCategory {
        let diff = score - par
        switch diff {
        case ..<(-1): return .eagle
        case -1:      return .birdie
        case 0:       return .par
        case 1:       return .bogey
        default:      return .double
        }
    }
}

// MARK: - Scoring Profile

struct ScoringProfile {
    let player: Player
    let eagle: Int
    let birdie: Int
    let par: Int
    let bogey: Int
    let double: Int
    let holesPlayed: Int

    init(player: Player, scores: [UUID: [Int: Int]], roundPar: [Int: Int] = Course.defaultPar) {
        self.player = player
        let holeScores = scores[player.id] ?? [:]
        var e = 0, b = 0, p = 0, bo = 0, d = 0
        for hole in 1...18 {
            guard let strokes = holeScores[hole],
                  let par = roundPar[hole] else { continue }
            switch ScoreCategory.category(for: strokes, par: par) {
            case .eagle:  e  += 1
            case .birdie: b  += 1
            case .par:    p  += 1
            case .bogey:  bo += 1
            case .double: d  += 1
            }
        }
        eagle = e; birdie = b; par = p; bogey = bo; double = d
        holesPlayed = holeScores.count
    }

    func count(for category: ScoreCategory) -> Int {
        switch category {
        case .eagle:  return eagle
        case .birdie: return birdie
        case .par:    return par
        case .bogey:  return bogey
        case .double: return double
        }
    }
}

// MARK: - Player Breakdown Row

struct PlayerBreakdownRow: View {
    let profile: ScoringProfile
    let showName: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if showName {
                Text(profile.player.name)
                    .font(.caption).foregroundStyle(.secondary)
                    .padding(.horizontal, 24)
            }

            GeometryReader { geo in
                HStack(spacing: 2) {
                    ForEach(ScoreCategory.allCases, id: \.self) { cat in
                        let count = profile.count(for: cat)
                        if count > 0 {
                            ZStack {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(cat.color)
                                Text("\(count)")
                                    .font(.caption2).fontWeight(.semibold)
                                    .foregroundStyle(.white)
                            }
                            .frame(width: segmentWidth(for: count, totalWidth: geo.size.width))
                        }
                    }
                }
            }
            .frame(height: 24)
            .padding(.horizontal, 24)
            .accessibilityIdentifier("summary.breakdownBar.\(profile.player.name)")
        }
    }

    private func segmentWidth(for count: Int, totalWidth: CGFloat) -> CGFloat {
        guard profile.holesPlayed > 0 else { return 0 }
        let usableWidth = totalWidth - (CGFloat(nonZeroCategoryCount - 1) * 2)
        return max(24, usableWidth * CGFloat(count) / CGFloat(profile.holesPlayed))
    }

    private var nonZeroCategoryCount: Int {
        ScoreCategory.allCases.filter { profile.count(for: $0) > 0 }.count
    }
}
