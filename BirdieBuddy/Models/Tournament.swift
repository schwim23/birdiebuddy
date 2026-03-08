
import Foundation
import SwiftData

@Model
final class Tournament {
    var id: UUID
    var name: String
    var startDate: Date
    var endDate: Date
    var inviteCode: String
    var organizerId: UUID
    var formatRaw: String
    var statusRaw: String
    var coursesPerRound: Int
    var numberOfRounds: Int
    var scoringConfigData: Data?

    @Relationship(deleteRule: .cascade, inverse: \TournamentPlayer.tournament)
    var players: [TournamentPlayer] = []

    @Relationship(deleteRule: .cascade, inverse: \TournamentRound.tournament)
    var tournamentRounds: [TournamentRound] = []

    @Relationship(deleteRule: .cascade, inverse: \TournamentGame.tournament)
    var games: [TournamentGame] = []

    init(
        id: UUID = UUID(),
        name: String = "",
        startDate: Date = Date(),
        endDate: Date = Date().addingTimeInterval(86400 * 3),
        inviteCode: String = "",
        organizerId: UUID = UUID(),
        format: TournamentFormat = .multiDay,
        numberOfRounds: Int = 3
    ) {
        self.id = id
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.inviteCode = inviteCode.isEmpty ? Self.generateInviteCode() : inviteCode
        self.organizerId = organizerId
        self.formatRaw = format.rawValue
        self.statusRaw = TournamentStatus.setup.rawValue
        self.coursesPerRound = 1
        self.numberOfRounds = numberOfRounds
    }

    var format: TournamentFormat {
        get { TournamentFormat(rawValue: formatRaw) ?? .multiDay }
        set { formatRaw = newValue.rawValue }
    }

    var status: TournamentStatus {
        get { TournamentStatus(rawValue: statusRaw) ?? .setup }
        set { statusRaw = newValue.rawValue }
    }

    var scoringConfig: TournamentScoringConfig {
        get {
            guard let data = scoringConfigData else { return TournamentScoringConfig() }
            return (try? JSONDecoder().decode(TournamentScoringConfig.self, from: data)) ?? TournamentScoringConfig()
        }
        set {
            scoringConfigData = try? JSONEncoder().encode(newValue)
        }
    }

    var sortedRounds: [TournamentRound] {
        tournamentRounds.sorted { $0.roundNumber < $1.roundNumber }
    }

    var currentRound: TournamentRound? {
        tournamentRounds.first { $0.status == .active }
    }

    var completedRoundCount: Int {
        tournamentRounds.filter { $0.status == .completed }.count
    }

    static func generateInviteCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<6).map { _ in chars.randomElement() ?? "A" })
    }
}

enum TournamentFormat: String, Codable, CaseIterable, Identifiable {
    case multiDay = "multi_day"
    case singleDay = "single_day"
    case ryder = "ryder"
    case bestBallPartnership = "best_ball_partnership"
    case roundRobin = "round_robin"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .multiDay: return "Multi-Day Outing"
        case .singleDay: return "Single Day Outing"
        case .ryder: return "Ryder Cup Style"
        case .bestBallPartnership: return "Best Ball Partnership"
        case .roundRobin: return "Round Robin"
        }
    }

    var description: String {
        switch self {
        case .multiDay: return "Multiple rounds over multiple days. Cumulative scoring across all rounds."
        case .singleDay: return "Multiple foursomes playing the same day with connected results."
        case .ryder: return "Two teams compete in alternating formats: Four Ball, Alternate Shot, and Singles."
        case .bestBallPartnership: return "Fixed partnerships across all rounds with best ball scoring."
        case .roundRobin: return "Each player/team plays against every other across rounds."
        }
    }

    var iconName: String {
        switch self {
        case .multiDay: return "calendar"
        case .singleDay: return "sun.max.fill"
        case .ryder: return "flag.2.crossed.fill"
        case .bestBallPartnership: return "person.2.fill"
        case .roundRobin: return "arrow.triangle.2.circlepath"
        }
    }
}

enum TournamentStatus: String, Codable {
    case setup
    case active
    case completed
    case cancelled
}

struct TournamentScoringConfig: Codable {
    var gameFormats: [String] = [] // GameFormat rawValues
    var useNetScoring: Bool = true
    var carryOverNassau: Bool = true
    var pointsPerRound: Bool = false
    var skinsCarryOver: Bool = true
    var handicapPercentage: Double = 100.0
    var nassauBetAmount: Double = 0.0
    var skinsBetAmount: Double = 0.0
    var teamPointsForWin: Int = 1
    var teamPointsForHalve: Int = 0
    var ryderSessionFormats: [String] = ["four_ball", "alternate_shot", "nassau"]
    var cumulativeStableford: Bool = false

    init() {}

    var activeGameFormats: [GameFormat] {
        gameFormats.compactMap { GameFormat(rawValue: $0) }
    }
}
