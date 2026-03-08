
import SwiftUI
import SwiftData

struct TripListScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query(sort: \Trip.startDate, order: .reverse) private var trips: [Trip]
    @State private var showNewTrip = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                if trips.isEmpty {
                    EmptyStateView(icon: "airplane", message: "No trips yet. Create one to track a golf outing!")
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(trips) { trip in
                                NavigationLink { TripDetailScreen(trip: trip) } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(trip.name).font(.subheadline.bold()).foregroundStyle(Theme.textPrimary)
                                            Text("\(trip.startDate.shortFormatted) – \(trip.endDate.shortFormatted)").font(.caption).foregroundStyle(Theme.textSecondary)
                                            Text("\(trip.rounds.count) rounds • Code: \(trip.inviteCode)").font(.caption).foregroundStyle(Theme.primaryGreen)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right").foregroundStyle(Theme.textSecondary)
                                    }.cardStyle()
                                }
                            }
                        }.padding()
                    }
                }
            }
            .navigationTitle("Trips").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .primaryAction) { Button { showNewTrip = true } label: { Image(systemName: "plus") } } }
            .sheet(isPresented: $showNewTrip) { NavigationStack { TripSetupScreen() } }
        }
    }
}
