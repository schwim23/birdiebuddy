
import SwiftUI
import SwiftData

struct TripDetailScreen: View {
    let trip: Trip
    @State private var vm = TripViewModel()

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                        Text(trip.name).font(.title2.bold()).foregroundStyle(Theme.textPrimary)
                        Text("\(trip.startDate.shortFormatted) – \(trip.endDate.shortFormatted)").font(.subheadline).foregroundStyle(Theme.textSecondary)
                        Text("Invite Code: \(trip.inviteCode)").font(.caption.monospaced()).foregroundStyle(Theme.primaryGreen)
                    }.padding()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Leaderboard").font(.headline).foregroundStyle(Theme.textPrimary)
                        let lb = vm.leaderboard(for: trip)
                        if lb.isEmpty { Text("No rounds completed yet.").font(.caption).foregroundStyle(Theme.textSecondary) }
                        else {
                            ForEach(lb) { entry in
                                HStack {
                                    Text("\(entry.position)").font(.headline).foregroundStyle(entry.position <= 3 ? Theme.accent : Theme.textSecondary).frame(width: 24)
                                    Text(entry.playerName).font(.subheadline).foregroundStyle(Theme.textPrimary)
                                    Spacer()
                                    VStack(alignment: .trailing) {
                                        Text("Net: \(entry.totalNetScore)").font(.subheadline.bold()).foregroundStyle(Theme.primaryGreen)
                                        Text("\(entry.roundsPlayed) rds").font(.caption).foregroundStyle(Theme.textSecondary)
                                    }
                                }
                            }
                        }
                    }.cardStyle()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Rounds").font(.headline).foregroundStyle(Theme.textPrimary)
                        if trip.rounds.isEmpty { Text("No rounds yet.").font(.caption).foregroundStyle(Theme.textSecondary) }
                        ForEach(trip.rounds.sorted(by: { $0.date > $1.date })) { round in
                            NavigationLink { RoundSummaryScreen(round: round) } label: {
                                HStack {
                                    Text(round.course?.name ?? "Unknown").font(.subheadline).foregroundStyle(Theme.textPrimary)
                                    Spacer()
                                    Text(round.date.shortFormatted).font(.caption).foregroundStyle(Theme.textSecondary)
                                }
                            }
                            Divider()
                        }
                    }.cardStyle()
                }.padding()
            }
        }
        .navigationTitle("Trip").navigationBarTitleDisplayMode(.inline)
    }
}
