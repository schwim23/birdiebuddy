
import Foundation
import SwiftData

@Model
final class Game {
    var id: UUID
    var formatRaw: String
    var configData: Data?
    var standingsData: Data?

    var round: GolfRound?

    @Relationship(deleteRule: .cascade, inverse: \Team.game)
    var teams: [Team] = []

    init(
        id: UUID = UUID(),
        format: GameFormat = .nassau,
        config: GameConfig? = nil
    ) {
        self.id = id
        self.formatRaw = format.rawValue
        if let config = config {
            self.configData = try? JSONEncoder().encode(config)
        }
    }

    var format: GameFormat {
        get { GameFormat(rawValue: formatRaw) ?? .nassau }
        set { formatRaw = newValue.rawValue }
    }

    var config: GameConfig {
        get {
            guard let data = configData else { return GameConfig() }
            return (try? JSONDecoder().decode(GameConfig.self, from: data)) ?? GameConfig()
        }
        set {
            configData = try? JSONEncoder().encode(newValue)
        }
    }

    var standings: GameStandings {
        get {
            guard let data = standingsData else { return GameStandings() }
            return (try? JSONDecoder().decode(GameStandings.self, from: data)) ?? GameStandings()
        }
        set {
            standingsData = try? JSONEncoder().encode(newValue)
        }
    }
}

struct GameConfig: Codable {
    var nassauAutoPress: Bool = false
    var nassauPressAfter: Int = 2
    var pointValue: Double = 1.0
    var wolfRotationOrder: [UUID] = []
    var useNetScores: Bool = true
    init() {}
}

struct GameStandings: Codable {
    var playerPoints: [String: Double] = [:]
    var teamPoints: [String: Double] = [:]
    var nassauFrontWinner: String?
    var nassauBackWinner: String?
    var nassauOverallWinner: String?
    var lastUpdatedHole: Int = 0
    init() {}
}

enum GameFormat: String, Codable, CaseIterable, Identifiable {
    case nassau = "nassau"
    case fourBall = "four_ball"
    case bestBall = "best_ball"
    case alternateShot = "alternate_shot"
    case scramble = "scramble"
    case shamble = "shamble"
    case wolf = "wolf"
    case fiveThreeOne = "five_three_one"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .nassau: return "Nassau"
        case .fourBall: return "Four Ball"
        case .bestBall: return "Best Ball"
        case .alternateShot: return "Alternate Shot"
        case .scramble: return "Scramble"
        case .shamble: return "Shamble"
        case .wolf: return "Wolf"
        case .fiveThreeOne: return "5-3-1"
        }
    }

    var description: String {
        switch self {
        case .nassau: return "Three bets: front 9, back 9, overall. Optional auto-press."
        case .fourBall: return "Two-person teams, best net score counts."
        case .bestBall: return "Lowest net score on each hole counts for team."
        case .alternateShot: return "Teams alternate hitting the same ball."
        case .scramble: return "Pick best shot, all play from there."
        case .shamble: return "Pick best drive, each plays own ball in."
        case .wolf: return "Rotating wolf picks partner or goes lone."
        case .fiveThreeOne: return "5 pts best, 3 second, 1 third, 0 worst."
        }
    }

    var minPlayers: Int {
        switch self {
        case .nassau: return 2
        case .fourBall, .alternateShot, .wolf, .fiveThreeOne: return 4
        case .bestBall, .scramble, .shamble: return 2
        }
    }

    var maxPlayers: Int { 4 }

    var requiresTeams: Bool {
        switch self {
        case .fourBall, .bestBall, .alternateShot, .scramble, .shamble: return true
        case .nassau, .wolf, .fiveThreeOne: return false
        }
    }

    var iconName: String {
        switch self {
        case .nassau: return "dollarsign.circle"
        case .fourBall: return "person.2"
        case .bestBall: return "star.circle"
        case .alternateShot: return "arrow.left.arrow.right"
        case .scramble: return "person.3"
        case .shamble: return "person.3.sequence"
        case .wolf: return "pawprint"
        case .fiveThreeOne: return "number.circle"
        }
    }
}
