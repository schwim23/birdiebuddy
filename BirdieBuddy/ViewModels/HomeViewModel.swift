
import SwiftUI
import SwiftData

@MainActor
@Observable
final class HomeViewModel {
    var recentRounds: [GolfRound] = []
    var activeTrips: [Trip] = []
    var tournaments: [Tournament] = []

    func loadData(modelContext: ModelContext) {
        var rd = FetchDescriptor<GolfRound>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        rd.fetchLimit = 20
        recentRounds = (try? modelContext.fetch(rd)) ?? []

        var td = FetchDescriptor<Trip>(sortBy: [SortDescriptor(\.startDate, order: .reverse)])
        td.fetchLimit = 10
        activeTrips = (try? modelContext.fetch(td)) ?? []

        var tnd = FetchDescriptor<Tournament>(sortBy: [SortDescriptor(\.startDate, order: .reverse)])
        tnd.fetchLimit = 10
        tournaments = (try? modelContext.fetch(tnd)) ?? []
    }

    func deleteRound(_ round: GolfRound, modelContext: ModelContext) {
        modelContext.delete(round)
        try? modelContext.save()
        loadData(modelContext: modelContext)
    }
}
