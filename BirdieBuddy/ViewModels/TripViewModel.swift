
import SwiftUI
import SwiftData

@MainActor
@Observable
final class TripViewModel {
    var tripName: String = ""
    var startDate: Date = Date()
    var endDate: Date = Date().addingTimeInterval(86400 * 3)

    func createTrip(organizerId: UUID, modelContext: ModelContext) -> Trip {
        let trip = Trip(name: tripName, startDate: startDate, endDate: endDate, organizerId: organizerId)
        modelContext.insert(trip)
        try? modelContext.save()
        return trip
    }

    func loadTrips(modelContext: ModelContext) -> [Trip] {
        var d = FetchDescriptor<Trip>(sortBy: [SortDescriptor(\.startDate, order: .reverse)])
        d.fetchLimit = 20
        return (try? modelContext.fetch(d)) ?? []
    }

    func leaderboard(for trip: Trip) -> [TripLeaderboardEntry] {
        var totals: [UUID: (name: String, net: Int, rounds: Int)] = [:]
        for round in trip.rounds {
            for player in round.players {
                let net = round.totalNetScore(for: player.playerId)
                if var e = totals[player.playerId] { e.net += net; e.rounds += 1; totals[player.playerId] = e }
                else { totals[player.playerId] = (player.displayName, net, 1) }
            }
        }
        var entries = totals.map { TripLeaderboardEntry(playerId: $0.key, playerName: $0.value.name, totalNetScore: $0.value.net, roundsPlayed: $0.value.rounds, position: 0) }
        entries.sort { $0.totalNetScore < $1.totalNetScore }
        for i in entries.indices { entries[i].position = i + 1 }
        return entries
    }
}

struct TripLeaderboardEntry: Identifiable {
    var id: UUID { playerId }
    var playerId: UUID
    var playerName: String
    var totalNetScore: Int
    var roundsPlayed: Int
    var position: Int
}
