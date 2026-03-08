
import SwiftUI

struct RoundSummaryScreen: View {
    let round: GolfRound

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Text(round.course?.name ?? "Round Complete").font(.title2.bold()).foregroundStyle(Theme.textPrimary)
                        Text(round.date.shortFormatted).font(.subheadline).foregroundStyle(Theme.textSecondary)
                        Text("\(round.holeCount) Holes").font(.caption).foregroundStyle(Theme.textSecondary)
                    }.padding()

                    // Scorecard
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Final Scores").font(.headline).foregroundStyle(Theme.textPrimary)
                        ForEach(round.players.sorted(by: { round.totalNetScore(for: $0.playerId) < round.totalNetScore(for: $1.playerId) })) { player in
                            HStack {
                                Text(player.displayName).font(.subheadline.bold()).foregroundStyle(Theme.textPrimary)
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("Gross: \(round.totalGrossScore(for: player.playerId))").font(.caption).foregroundStyle(Theme.textSecondary)
                                    Text("Net: \(round.totalNetScore(for: player.playerId))").font(.subheadline.bold()).foregroundStyle(Theme.primaryGreen)
                                }
                            }
                            Divider()
                        }
                    }.cardStyle()

                    // Hole by hole
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Hole-by-Hole").font(.headline).foregroundStyle(Theme.textPrimary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            VStack(spacing: 4) {
                                // Header
                                HStack(spacing: 0) {
                                    Text("Player").font(.caption2.bold()).frame(width: 80, alignment: .leading)
                                    ForEach(1...round.holeCount, id: \.self) { h in
                                        Text("\(h)").font(.caption2.bold()).frame(width: 28)
                                    }
                                    Text("Tot").font(.caption2.bold()).frame(width: 36)
                                }.foregroundStyle(Theme.textSecondary)
                                // Par row
                                HStack(spacing: 0) {
                                    Text("Par").font(.caption2).frame(width: 80, alignment: .leading)
                                    ForEach(round.course?.sortedHoles ?? [], id: \.id) { hole in
                                        Text("\(hole.par)").font(.caption2).frame(width: 28)
                                    }
                                    Text("\(round.course?.totalPar ?? 0)").font(.caption2.bold()).frame(width: 36)
                                }.foregroundStyle(Theme.textSecondary)
                                // Player rows
                                ForEach(round.players) { player in
                                    HStack(spacing: 0) {
                                        Text(player.displayName).font(.caption2).frame(width: 80, alignment: .leading).lineLimit(1)
                                        ForEach(1...round.holeCount, id: \.self) { h in
                                            let score = round.scores.first { $0.playerId == player.playerId && $0.holeNumber == h }
                                            let par = round.course?.sortedHoles.first { $0.number == h }?.par ?? 4
                                            let gross = score?.grossScore ?? 0
                                            let st = ScoreType.from(gross: gross, par: par)
                                            Text(gross > 0 ? "\(gross)" : "-")
                                                .font(.caption2.bold())
                                                .foregroundStyle(gross > 0 ? st.color : Theme.textSecondary)
                                                .frame(width: 28)
                                        }
                                        Text("\(round.totalGrossScore(for: player.playerId))").font(.caption2.bold()).frame(width: 36)
                                    }.foregroundStyle(Theme.textPrimary)
                                }
                            }
                        }
                    }.cardStyle()

                    // Game results
                    ForEach(round.games) { game in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack { Image(systemName: game.format.iconName); Text(game.format.displayName).font(.headline) }.foregroundStyle(Theme.textPrimary)
                            let engine = GameEngineFactory.engine(for: game.format)
                            let standings = engine.calculateStandings(round: round, game: game)
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

                    Spacer(minLength: 40)
                }.padding()
            }
        }
        .navigationTitle("Round Summary").navigationBarTitleDisplayMode(.inline)
    }
}
