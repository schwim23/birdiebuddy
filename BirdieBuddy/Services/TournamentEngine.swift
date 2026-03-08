
import Foundation

@MainActor
@Observable
final class TournamentEngine {
    var tournament: Tournament
    var leaderboard: [TournamentLeaderboardEntry] = []
    var teamStandings: [TeamStanding] = []
    var roundSummaries: [RoundSummary] = []
    var gameStandings: [GameFormatStanding] = []

    init(tournament: Tournament) {
        self.tournament = tournament
    }

    // MARK: - Calculate Full Leaderboard

    func recalculate() {
        calculateLeaderboard()
        calculateTeamStandings()
        calculateRoundSummaries()
        calculateGameFormatStandings()
        updateTournamentPlayerPoints()
    }

    private func calculateLeaderboard() {
        var entries: [UUID: TournamentLeaderboardEntry] = [:]

        // Initialize entries for all players
        for player in tournament.players {
            entries[player.playerId] = TournamentLeaderboardEntry(
                playerId: player.playerId,
                playerName: player.displayName,
                teamTag: player.teamTag,
                handicapIndex: player.handicapIndex
            )
        }

        // Aggregate scores from all completed foursomes across all rounds
        for tRound in tournament.sortedRounds {
            for foursome in tRound.sortedFoursomes {
                guard let golfRound = foursome.golfRound else { continue }

                for player in golfRound.players {
                    guard var entry = entries[player.playerId] else { continue }

                    let grossTotal = golfRound.totalGrossScore(for: player.playerId)
                    let netTotal = golfRound.totalNetScore(for: player.playerId)
                    let holesScored = golfRound.scoresForPlayer(player.playerId).count

                    if holesScored > 0 {
                        entry.totalGrossScore += grossTotal
                        entry.totalNetScore += netTotal
                        entry.roundsPlayed += 1
                        entry.holesPlayed += holesScored

                        entry.roundDetails.append(
                            TournamentLeaderboardEntry.RoundDetail(
                                roundNumber: tRound.roundNumber,
                                courseName: tRound.courseName,
                                grossScore: grossTotal,
                                netScore: netTotal,
                                holesPlayed: holesScored
                            )
                        )

                        // Calculate game points from this round's games
                        for game in golfRound.games {
                            let engine = GameEngineFactory.engine(for: game.format)
                            let standings = engine.calculateStandings(round: golfRound, game: game)
                            if let playerStanding = standings.first(where: { $0.playerId == player.playerId }) {
                                entry.gamePoints += playerStanding.points
                            }
                        }
                    }

                    entries[player.playerId] = entry
                }
            }
        }

        var result = Array(entries.values)
        result.sort { lhs, rhs in
            if lhs.totalNetScore != rhs.totalNetScore {
                return lhs.totalNetScore < rhs.totalNetScore
            }
            return lhs.gamePoints > rhs.gamePoints
        }

        for i in result.indices {
            result[i].position = i + 1
        }

        leaderboard = result
    }

    private func calculateTeamStandings() {
        var teamScores: [String: TeamStanding] = [:]

        for entry in leaderboard where !entry.teamTag.isEmpty {
            var team = teamScores[entry.teamTag] ?? TeamStanding(
                teamTag: entry.teamTag,
                playerNames: [],
                totalNetScore: 0,
                totalGrossScore: 0,
                totalGamePoints: 0,
                matchesWon: 0,
                matchesLost: 0,
                matchesHalved: 0
            )

            team.playerNames.append(entry.playerName)
            team.totalNetScore += entry.totalNetScore
            team.totalGrossScore += entry.totalGrossScore
            team.totalGamePoints += entry.gamePoints

            teamScores[entry.teamTag] = team
        }

        var result = Array(teamScores.values)
        result.sort { $0.totalNetScore < $1.totalNetScore }
        for i in result.indices {
            result[i].position = i + 1
        }

        teamStandings = result
    }

    private func calculateRoundSummaries() {
        roundSummaries = tournament.sortedRounds.map { tRound in
            var foursomeResults: [FoursomeResult] = []

            for foursome in tRound.sortedFoursomes {
                guard let golfRound = foursome.golfRound else {
                    foursomeResults.append(FoursomeResult(
                        foursomeId: foursome.id,
                        groupName: foursome.groupName,
                        playerNames: foursome.playerNames,
                        isComplete: false,
                        scores: [],
                        gameResults: []
                    ))
                    continue
                }

                var scores: [FoursomeResult.PlayerScore] = []
                for player in golfRound.players {
                    scores.append(FoursomeResult.PlayerScore(
                        playerId: player.playerId,
                        playerName: player.displayName,
                        grossScore: golfRound.totalGrossScore(for: player.playerId),
                        netScore: golfRound.totalNetScore(for: player.playerId),
                        holesCompleted: golfRound.scoresForPlayer(player.playerId).count
                    ))
                }

                var gameResults: [FoursomeResult.GameResult] = []
                for game in golfRound.games {
                    let engine = GameEngineFactory.engine(for: game.format)
                    let standings = engine.calculateStandings(round: golfRound, game: game)
                    gameResults.append(FoursomeResult.GameResult(
                        format: game.format.displayName,
                        standings: standings
                    ))
                }

                foursomeResults.append(FoursomeResult(
                    foursomeId: foursome.id,
                    groupName: foursome.groupName,
                    playerNames: foursome.playerNames,
                    isComplete: golfRound.roundStatus == .completed,
                    scores: scores,
                    gameResults: gameResults
                ))
            }

            return RoundSummary(
                roundNumber: tRound.roundNumber,
                courseName: tRound.courseName,
                date: tRound.date,
                status: tRound.status,
                foursomeResults: foursomeResults
            )
        }
    }

    private func calculateGameFormatStandings() {
        let config = tournament.scoringConfig
        var formatAggregates: [String: [UUID: GameFormatStanding.PlayerFormatScore]] = [:]

        for tRound in tournament.sortedRounds {
            for foursome in tRound.sortedFoursomes {
                guard let golfRound = foursome.golfRound else { continue }

                for game in golfRound.games {
                    let formatKey = game.formatRaw
                    let engine = GameEngineFactory.engine(for: game.format)
                    let standings = engine.calculateStandings(round: golfRound, game: game)

                    for standing in standings {
                        var agg = formatAggregates[formatKey, default: [:]]
                        var playerScore = agg[standing.playerId] ?? GameFormatStanding.PlayerFormatScore(
                            playerId: standing.playerId,
                            playerName: standing.playerName,
                            totalPoints: 0,
                            roundPoints: []
                        )

                        playerScore.totalPoints += standing.points
                        playerScore.roundPoints.append(
                            GameFormatStanding.PlayerFormatScore.RoundPoints(
                                roundNumber: tRound.roundNumber,
                                points: standing.points
                            )
                        )

                        agg[standing.playerId] = playerScore
                        formatAggregates[formatKey] = agg
                    }
                }
            }
        }

        gameStandings = formatAggregates.map { key, playersMap in
            var players = Array(playersMap.values)
            players.sort { $0.totalPoints > $1.totalPoints }
            return GameFormatStanding(
                formatRaw: key,
                formatDisplayName: GameFormat(rawValue: key)?.displayName ?? key,
                playerScores: players
            )
        }
    }

    private func updateTournamentPlayerPoints() {
        for player in tournament.players {
            if let entry = leaderboard.first(where: { $0.playerId == player.playerId }) {
                var points: [String: Double] = [:]
                for gs in gameStandings {
                    if let ps = gs.playerScores.first(where: { $0.playerId == player.playerId }) {
                        points[gs.formatRaw] = ps.totalPoints
                    }
                }
                player.cumulativePoints = points
            }
        }
    }

    // MARK: - Nassau Carry Over

    func processNassauCarryOver(from completedRound: TournamentRound) {
        guard tournament.scoringConfig.carryOverNassau else { return }

        for tGame in tournament.games where tGame.format == .nassau {
            var carryOver = tGame.nassauCarryOver

            for foursome in completedRound.sortedFoursomes {
                guard let golfRound = foursome.golfRound else { continue }

                for game in golfRound.games where game.format == .nassau {
                    let nassauEngine = NassauEngine()
                    let standings = nassauEngine.calculateStandings(round: golfRound, game: game)

                    guard standings.count >= 2 else { continue }
                    let winner = standings[0]
                    let loser = standings[standings.count - 1]

                    let diff = loser.points - winner.points
                    let winnerKey = winner.playerId.uuidString
                    let loserKey = loser.playerId.uuidString

                    carryOver.playerBalances[winnerKey, default: 0] += diff
                    carryOver.playerBalances[loserKey, default: 0] -= diff
                }
            }

            tGame.nassauCarryOver = carryOver
        }
    }

    // MARK: - Pairing Helpers

    func generateRandomPairings(for roundNumber: Int) -> [[UUID]] {
        var playerIds = tournament.players.map { $0.playerId }
        playerIds.shuffle()

        var pairings: [[UUID]] = []
        while !playerIds.isEmpty {
            let groupSize = min(4, playerIds.count)
            let group = Array(playerIds.prefix(groupSize))
            pairings.append(group)
            playerIds.removeFirst(groupSize)
        }

        return pairings
    }

    func generateRyderPairings(for roundNumber: Int) -> [[UUID]] {
        let teamA = tournament.players.filter { $0.teamTag == "Team A" }.map { $0.playerId }
        let teamB = tournament.players.filter { $0.teamTag == "Team B" }.map { $0.playerId }

        var pairings: [[UUID]] = []
        let pairCount = min(teamA.count / 2, teamB.count / 2)

        for i in 0..<pairCount {
            let a1 = teamA[i * 2]
            let a2 = teamA[i * 2 + 1]
            let b1 = teamB[i * 2]
            let b2 = teamB[i * 2 + 1]
            pairings.append([a1, a2, b1, b2])
        }

        return pairings
    }
}

// MARK: - Leaderboard Types

struct TournamentLeaderboardEntry: Identifiable {
    var id: UUID { playerId }
    var playerId: UUID
    var playerName: String
    var teamTag: String
    var handicapIndex: Double
    var position: Int = 0
    var totalGrossScore: Int = 0
    var totalNetScore: Int = 0
    var roundsPlayed: Int = 0
    var holesPlayed: Int = 0
    var gamePoints: Double = 0
    var roundDetails: [RoundDetail] = []

    struct RoundDetail: Identifiable {
        var id: UUID = UUID()
        var roundNumber: Int
        var courseName: String
        var grossScore: Int
        var netScore: Int
        var holesPlayed: Int
    }

    var averageNetPerRound: Double {
        guard roundsPlayed > 0 else { return 0 }
        return Double(totalNetScore) / Double(roundsPlayed)
    }
}

struct TeamStanding: Identifiable {
    var id: String { teamTag }
    var teamTag: String
    var playerNames: [String]
    var totalNetScore: Int
    var totalGrossScore: Int
    var totalGamePoints: Double
    var matchesWon: Int
    var matchesLost: Int
    var matchesHalved: Int
    var position: Int = 0
}

struct RoundSummary: Identifiable {
    var id: Int { roundNumber }
    var roundNumber: Int
    var courseName: String
    var date: Date
    var status: TournamentRoundStatus
    var foursomeResults: [FoursomeResult]
}

struct FoursomeResult: Identifiable {
    var id: UUID { foursomeId }
    var foursomeId: UUID
    var groupName: String
    var playerNames: [String]
    var isComplete: Bool
    var scores: [PlayerScore]
    var gameResults: [GameResult]

    struct PlayerScore: Identifiable {
        var id: UUID { playerId }
        var playerId: UUID
        var playerName: String
        var grossScore: Int
        var netScore: Int
        var holesCompleted: Int
    }

    struct GameResult: Identifiable {
        var id: String { format }
        var format: String
        var standings: [PlayerStanding]
    }
}

struct GameFormatStanding: Identifiable {
    var id: String { formatRaw }
    var formatRaw: String
    var formatDisplayName: String
    var playerScores: [PlayerFormatScore]

    struct PlayerFormatScore: Identifiable {
        var id: UUID { playerId }
        var playerId: UUID
        var playerName: String
        var totalPoints: Double
        var roundPoints: [RoundPoints]

        struct RoundPoints: Identifiable, Codable {
            var id: UUID = UUID()
            var roundNumber: Int
            var points: Double
        }
    }
}
