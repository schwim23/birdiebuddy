
import SwiftUI
import SwiftData

@MainActor
@Observable
final class RoundSetupViewModel {
    var selectedCourse: Course?
    var holeCount: Int = 18
    var players: [PlayerEntry] = [PlayerEntry()]
    var selectedFormats: Set<GameFormat> = []

    struct PlayerEntry: Identifiable {
        var id = UUID()
        var name: String = ""
        var handicap: Double = 0.0
    }

    func addPlayer() { if players.count < 4 { players.append(PlayerEntry()) } }
    func removePlayer(at i: Int) { guard players.count > 1, i < players.count else { return }; players.remove(at: i) }

    var canStartRound: Bool {
        selectedCourse != nil && players.allSatisfy { !$0.name.isEmpty } && !players.isEmpty
    }

    func validateFormats() -> String? {
        for f in selectedFormats {
            if players.count < f.minPlayers {
                return "\(f.displayName) requires at least \(f.minPlayers) players"
            }
            if players.count > f.maxPlayers {
                return "\(f.displayName) allows at most \(f.maxPlayers) players"
            }
        }
        return nil
    }

    func createRound(modelContext: ModelContext) -> GolfRound? {
        guard let course = selectedCourse else { return nil }
        let round = GolfRound(holeCount: holeCount, status: RoundStatus.active.rawValue)
        round.course = course

        for entry in players {
            let courseHcp = HandicapCalculator.courseHandicap(
                handicapIndex: entry.handicap,
                slopeRating: course.slopeRating,
                courseRating: course.courseRating,
                par: course.totalPar
            )
            let player = RoundPlayer(displayName: entry.name, courseHandicap: courseHcp, playerId: entry.id)
            player.calculateAndStoreStrokes(holes: course.sortedHoles)
            player.round = round
            round.players.append(player)
        }

        for format in selectedFormats {
            let game = Game(format: format)
            game.round = round
            round.games.append(game)
        }

        modelContext.insert(round)
        try? modelContext.save()
        return round
    }
}
