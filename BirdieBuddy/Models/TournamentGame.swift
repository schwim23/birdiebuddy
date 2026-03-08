
import Foundation
import SwiftData

@Model
final class TournamentGame {
    var id: UUID
    var formatRaw: String
    var standingsData: Data?
    var nassauCarryOverData: Data?

    var tournament: Tournament?

    init(
        id: UUID = UUID(),
        format: GameFormat = .nassau
    ) {
        self.id = id
        self.formatRaw = format.rawValue
    }

    var format: GameFormat {
        get { GameFormat(rawValue: formatRaw) ?? .nassau }
        set { formatRaw = newValue.rawValue }
    }

    /// Cumulative standings across all rounds
    var cumulativeStandings: [TournamentPlayerScore] {
        get {
            guard let data = standingsData else { return [] }
            return (try? JSONDecoder().decode([TournamentPlayerScore].self, from: data)) ?? []
        }
        set {
            standingsData = try? JSONEncoder().encode(newValue)
        }
    }

    /// Nassau carry-over data between rounds
    var nassauCarryOver: NassauCarryOver {
        get {
            guard let data = nassauCarryOverData else { return NassauCarryOver() }
            return (try? JSONDecoder().decode(NassauCarryOver.self, from: data)) ?? NassauCarryOver()
        }
        set {
            nassauCarryOverData = try? JSONEncoder().encode(newValue)
        }
    }
}

struct TournamentPlayerScore: Codable, Identifiable {
    var id: UUID = UUID()
    var playerId: UUID
    var playerName: String
    var teamTag: String
    var totalPoints: Double
    var totalNetScore: Int
    var totalGrossScore: Int
    var roundScores: [RoundScore]
    var nassauRecord: NassauRecord
    var matchesWon: Int
    var matchesLost: Int
    var matchesHalved: Int

    struct RoundScore: Codable {
        var roundNumber: Int
        var grossScore: Int
        var netScore: Int
        var points: Double
    }

    struct NassauRecord: Codable {
        var frontWins: Int = 0
        var frontLosses: Int = 0
        var backWins: Int = 0
        var backLosses: Int = 0
        var overallWins: Int = 0
        var overallLosses: Int = 0
        var pressWins: Int = 0
        var pressLosses: Int = 0

        var totalWins: Int { frontWins + backWins + overallWins + pressWins }
        var totalLosses: Int { frontLosses + backLosses + overallLosses + pressLosses }
    }

    init(playerId: UUID, playerName: String, teamTag: String = "") {
        self.id = UUID()
        self.playerId = playerId
        self.playerName = playerName
        self.teamTag = teamTag
        self.totalPoints = 0
        self.totalNetScore = 0
        self.totalGrossScore = 0
        self.roundScores = []
        self.nassauRecord = NassauRecord()
        self.matchesWon = 0
        self.matchesLost = 0
        self.matchesHalved = 0
    }
}

struct NassauCarryOver: Codable {
    var playerBalances: [String: Double] = [:] // playerId string -> running balance
    var pressesActive: [String: Int] = [:] // playerId string -> active press count
    var skinsCarryOver: Int = 0

    init() {}
}
