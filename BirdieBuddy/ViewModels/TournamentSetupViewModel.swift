
import SwiftUI
import SwiftData

@MainActor
@Observable
final class TournamentSetupViewModel {
    var name: String = ""
    var startDate: Date = Date()
    var endDate: Date = Date().addingTimeInterval(86400 * 3)
    var format: TournamentFormat = .multiDay
    var numberOfRounds: Int = 3
    var playerEntries: [PlayerEntry] = []
    var selectedGameFormats: Set<GameFormat> = [.nassau]
    var useNetScoring: Bool = true
    var carryOverNassau: Bool = true
    var isRyderStyle: Bool = false

    // Round-specific course assignments
    var roundCourseNames: [String] = ["", "", ""]

    struct PlayerEntry: Identifiable {
        var id = UUID()
        var name: String = ""
        var handicap: Double = 0.0
        var teamTag: String = ""
    }

    var canCreate: Bool {
        !name.isEmpty && playerEntries.count >= 2 && playerEntries.allSatisfy { !$0.name.isEmpty }
    }

    var playerCount: Int { playerEntries.count }

    func addPlayer() {
        playerEntries.append(PlayerEntry())
    }

    func removePlayer(at index: Int) {
        guard index < playerEntries.count, playerEntries.count > 2 else { return }
        playerEntries.remove(at: index)
    }

    func updateRoundCount(_ count: Int) {
        numberOfRounds = max(1, min(count, 10))
        while roundCourseNames.count < numberOfRounds {
            roundCourseNames.append("")
        }
        while roundCourseNames.count > numberOfRounds {
            roundCourseNames.removeLast()
        }
    }

    func createTournament(organizerId: UUID, modelContext: ModelContext) -> Tournament {
        let tournament = Tournament(
            name: name,
            startDate: startDate,
            endDate: endDate,
            organizerId: organizerId,
            format: format,
            numberOfRounds: numberOfRounds
        )

        var config = TournamentScoringConfig()
        config.gameFormats = selectedGameFormats.map { $0.rawValue }
        config.useNetScoring = useNetScoring
        config.carryOverNassau = carryOverNassau
        tournament.scoringConfig = config

        // Add players
        for (index, entry) in playerEntries.enumerated() {
            let tPlayer = TournamentPlayer(
                playerId: entry.id,
                displayName: entry.name,
                handicapIndex: entry.handicap,
                teamTag: entry.teamTag,
                isOrganizer: index == 0
            )
            tPlayer.tournament = tournament
            tournament.players.append(tPlayer)
        }

        // Create rounds
        for roundNum in 1...numberOfRounds {
            let tRound = TournamentRound(
                roundNumber: roundNum,
                date: startDate.addingTimeInterval(Double(roundNum - 1) * 86400),
                courseName: roundNum <= roundCourseNames.count ? roundCourseNames[roundNum - 1] : ""
            )
            tRound.tournament = tournament
            tournament.tournamentRounds.append(tRound)
        }

        // Create tournament-level game trackers
        for format in selectedGameFormats {
            let tGame = TournamentGame(format: format)
            tGame.tournament = tournament
            tournament.games.append(tGame)
        }

        modelContext.insert(tournament)
        try? modelContext.save()
        return tournament
    }
}
