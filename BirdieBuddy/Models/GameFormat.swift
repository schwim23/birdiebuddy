import Foundation

enum GameFormat: String, CaseIterable, Codable {
    case strokePlay    = "Stroke Play"
    case matchPlay     = "Match Play"
    case bestBall      = "Best Ball"
    case wolf          = "Wolf"
    case fiveThreeOne  = "5-3-1"

    /// Valid player-count range for this format.
    var playerRange: ClosedRange<Int> {
        switch self {
        case .strokePlay:             return 1...4
        case .matchPlay:              return 2...2
        case .bestBall, .wolf, .fiveThreeOne: return 4...4
        }
    }

    func isCompatible(with count: Int) -> Bool { playerRange.contains(count) }

    /// True when the format uses two teams.
    var isTeamFormat: Bool { self == .bestBall }
}

enum HoleResult: Equatable {
    case playerWins(Player)
    case teamWins(teamIndex: Int)
    case halved
}

struct WolfHoleState {
    let wolfPlayerID: UUID
    var partnerPlayerID: UUID?  // nil until decided
    var isLoneWolf: Bool = false
    var isDecided: Bool = false
}
