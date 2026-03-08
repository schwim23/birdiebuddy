
import SwiftUI

struct MatchStatusScreen: View {
    let vm: ScorecardViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    if vm.round.games.isEmpty {
                        EmptyStateView(icon: "trophy", message: "No game formats selected for this round.")
                    }
                    ForEach(vm.round.games) { game in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: game.format.iconName)
                                Text(game.format.displayName).font(.headline)
                            }.foregroundStyle(Theme.textPrimary)

                            let standings = vm.gameStandings(for: game)
                            ForEach(standings) { s in
                                HStack {
                                    Text("\(s.position)").font(.headline).foregroundStyle(s.position == 1 ? Theme.accent : Theme.textSecondary).frame(width: 24)
                                    Text(s.playerName).font(.subheadline).foregroundStyle(Theme.textPrimary)
                                    Spacer()
                                    Text(s.matchStatus).font(.caption.monospaced()).foregroundStyle(Theme.textSecondary)
                                }
                            }
                        }.cardStyle()
                    }
                }.padding()
            }
        }
        .navigationTitle("Match Status").navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
    }
}
