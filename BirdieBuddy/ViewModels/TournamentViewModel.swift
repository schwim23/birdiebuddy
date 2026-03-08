
import SwiftUI
import SwiftData

@MainActor
@Observable
final class TournamentViewModel {
    var tournament: Tournament
    var engine: TournamentEngine
    var showPairingEditor: Bool = false
    var editingRound: TournamentRound?
    var pairingDraft: [[PairingSlot]] = []

    struct PairingSlot: Identifiable {
        var id = UUID()
        var playerId: UUID?
        var playerName: String = ""
    }

    init(tournament: Tournament) {
        self.tournament = tournament
        self.engine = TournamentEngine(tournament: tournament)
    }

    func refresh() {
        engine.recalculate()
    }

    // MARK: - Pairing Management

    func startEditingPairings(for round: TournamentRound) {
        editingRound = round
        let existing = round.pairings
        let allPlayers = tournament.players

        if existing.isEmpty {
            // Generate initial pairings
            let ids = tournament.format == .ryder
                ? engine.generateRyderPairings(for: round.roundNumber)
                : engine.generateRandomPairings(for: round.roundNumber)

            pairingDraft = ids.map { group in
                group.map { pid in
                    let name = allPlayers.first { $0.playerId == pid }?.displayName ?? "?"
                    return PairingSlot(playerId: pid, playerName: name)
                }
            }
        } else {
            pairingDraft = existing.map { group in
                group.map { pid in
                    let name = allPlayers.first { $0.playerId == pid }?.displayName ?? "?"
                    return PairingSlot(playerId: pid, playerName: name)
                }
            }
        }

        showPairingEditor = true
    }

    func savePairings(modelContext: ModelContext) {
        guard let round = editingRound else { return }

        let pairings = pairingDraft.map { group in
            group.compactMap { $0.playerId }
        }
        round.pairings = pairings

        // Create Foursome objects
        let existingFoursomes = round.foursomes
        for fs in existingFoursomes {
            modelContext.delete(fs)
        }
        round.foursomes = []

        for (index, group) in pairings.enumerated() {
            let names = group.compactMap { pid in
                tournament.players.first { $0.playerId == pid }?.displayName
            }
            let foursome = Foursome(
                groupNumber: index + 1,
                groupName: "Group \(index + 1)",
                playerIds: group,
                playerNames: names
            )
            foursome.tournamentRound = round
            round.foursomes.append(foursome)
        }

        try? modelContext.save()
        showPairingEditor = false
    }

    func shufflePairings() {
        let allSlots = pairingDraft.flatMap { $0 }.shuffled()
        var newDraft: [[PairingSlot]] = []
        var remaining = allSlots

        while !remaining.isEmpty {
            let groupSize = min(4, remaining.count)
            let group = Array(remaining.prefix(groupSize))
            newDraft.append(group)
            remaining.removeFirst(groupSize)
        }

        pairingDraft = newDraft
    }

    // MARK: - Round Management

    func startRound(_ round: TournamentRound, course: Course, modelContext: ModelContext) {
        round.status = .active
        round.courseId = course.id
        round.courseName = course.name

        let config = tournament.scoringConfig

        for foursome in round.sortedFoursomes {
            let golfRound = GolfRound(
                holeCount: course.holes.count > 9 ? 18 : 9,
                status: RoundStatus.active.rawValue
            )
            golfRound.course = course

            for playerId in foursome.playerIds {
                guard let tPlayer = tournament.players.first(where: { $0.playerId == playerId }) else { continue }

                let courseHcp = HandicapCalculator.courseHandicap(
                    handicapIndex: tPlayer.handicapIndex * (config.handicapPercentage / 100.0),
                    slopeRating: course.slopeRating,
                    courseRating: course.courseRating,
                    par: course.totalPar
                )

                let roundPlayer = RoundPlayer(
                    displayName: tPlayer.displayName,
                    courseHandicap: courseHcp,
                    playerId: tPlayer.playerId
                )
                roundPlayer.calculateAndStoreStrokes(holes: course.sortedHoles)
                roundPlayer.round = golfRound
                golfRound.players.append(roundPlayer)
            }

            // Add game formats from tournament config
            for formatRaw in config.gameFormats {
                if let format = GameFormat(rawValue: formatRaw) {
                    let game = Game(format: format)
                    game.round = golfRound
                    golfRound.games.append(game)
                }
            }

            foursome.golfRound = golfRound
            modelContext.insert(golfRound)
        }

        if tournament.status == .setup {
            tournament.status = .active
        }

        try? modelContext.save()
    }

    func completeRound(_ round: TournamentRound, modelContext: ModelContext) {
        round.status = .completed

        // Process carry-overs
        engine.processNassauCarryOver(from: round)

        // Check if all rounds complete
        if tournament.sortedRounds.allSatisfy({ $0.status == .completed }) {
            tournament.status = .completed
        }

        engine.recalculate()
        try? modelContext.save()
    }

    func movePlayer(in groupIndex: Int, from source: IndexSet, to destination: Int) {
        guard groupIndex < pairingDraft.count else { return }
        pairingDraft[groupIndex].move(fromOffsets: source, toOffset: destination)
    }
}
