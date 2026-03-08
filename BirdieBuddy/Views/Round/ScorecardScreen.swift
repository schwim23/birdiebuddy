
import SwiftUI
import SwiftData

struct ScorecardScreen: View {
    @Environment(\.modelContext) private var modelContext
    @State private var vm: ScorecardViewModel
    @State private var voiceService = VoiceService()

    init(round: GolfRound) { _vm = State(initialValue: ScorecardViewModel(round: round)) }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                // Hole header
                HStack {
                    Button { vm.previousHole() } label: { Image(systemName: "chevron.left").font(.title3).foregroundStyle(vm.currentHole > 1 ? Theme.primaryGreen : Theme.textSecondary) }
                        .disabled(vm.currentHole <= 1)
                    Spacer()
                    VStack(spacing: 2) {
                        Text("Hole \(vm.currentHole)").font(.title2.bold()).foregroundStyle(Theme.textPrimary)
                        HStack(spacing: 12) {
                            Text("Par \(vm.currentHolePar)").font(.subheadline).foregroundStyle(Theme.textSecondary)
                            if let y = vm.currentHoleInfo?.yardage { Text("\(y) yds").font(.subheadline).foregroundStyle(Theme.textSecondary) }
                            Text("HCP \(vm.currentHoleInfo?.handicapRating ?? 0)").font(.caption).foregroundStyle(Theme.textSecondary)
                        }
                    }
                    Spacer()
                    Button { vm.nextHole() } label: { Image(systemName: "chevron.right").font(.title3).foregroundStyle(vm.currentHole < vm.maxHole ? Theme.primaryGreen : Theme.textSecondary) }
                        .disabled(vm.currentHole >= vm.maxHole)
                }
                .padding()
                .background(Theme.cardBackground)

                // Hole picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(1...vm.maxHole, id: \.self) { h in
                            Button { vm.goToHole(h) } label: {
                                Text("\(h)").font(.caption.bold())
                                    .frame(width: 30, height: 30)
                                    .background(vm.currentHole == h ? Theme.primaryGreen : (vm.allHolesScored(for: h) ? Theme.secondaryGreen.opacity(0.3) : Theme.cardBackground))
                                    .foregroundStyle(vm.currentHole == h ? .white : Theme.textPrimary)
                                    .clipShape(Circle())
                            }
                        }
                    }.padding(.horizontal)
                }.padding(.vertical, 8)

                Divider()

                // Player scores
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(vm.round.players) { player in
                            PlayerScoreRow(player: player, vm: vm, modelContext: modelContext)
                        }
                    }.padding()
                }

                Divider()

                // Bottom bar
                HStack(spacing: 16) {
                    Button { vm.showVoiceInput = true } label: {
                        HStack {
                            Image(systemName: "mic.fill").font(.title3)
                            Text("Voice").font(.subheadline.bold())
                        }
                        .foregroundStyle(.white).padding(.horizontal, 20).padding(.vertical, 12)
                        .background(Theme.primaryGreen).clipShape(Capsule())
                    }

                    Button { vm.showMatchStatus = true } label: {
                        HStack {
                            Image(systemName: "chart.bar.fill").font(.title3)
                            Text("Match").font(.subheadline.bold())
                        }
                        .foregroundStyle(Theme.primaryGreen).padding(.horizontal, 20).padding(.vertical, 12)
                        .background(Theme.lightGreen).clipShape(Capsule())
                    }

                    Button { vm.showVideoRecord = true } label: {
                        Image(systemName: "video.fill").font(.title3)
                            .foregroundStyle(Theme.primaryGreen).padding(12)
                            .background(Theme.lightGreen).clipShape(Circle())
                    }

                    if vm.currentHole == vm.maxHole && vm.allHolesScored(for: vm.maxHole) {
                        Button { vm.completeRound(modelContext: modelContext) } label: {
                            Text("Finish").font(.subheadline.bold())
                                .foregroundStyle(.white).padding(.horizontal, 20).padding(.vertical, 12)
                                .background(Theme.accent).clipShape(Capsule())
                        }
                    }
                }
                .padding()
                .background(Theme.cardBackground)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(vm.round.course?.name ?? "Scorecard")
        .sheet(isPresented: $vm.showVoiceInput) { VoiceInputOverlay(vm: vm, voiceService: voiceService, modelContext: modelContext) }
        .sheet(isPresented: $vm.showMatchStatus) { NavigationStack { MatchStatusScreen(vm: vm) } }
        .sheet(isPresented: $vm.showVideoRecord) { NavigationStack { VideoRecordScreen(round: vm.round, currentHole: vm.currentHole) } }
    }
}

private struct PlayerScoreRow: View {
    let player: RoundPlayer
    let vm: ScorecardViewModel
    let modelContext: ModelContext
    @State private var scoreText = ""

    var body: some View {
        let existing = vm.scoreForPlayer(player.playerId)
        let strokes = player.strokesReceived[vm.currentHole] ?? 0

        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(player.displayName).font(.subheadline.bold()).foregroundStyle(Theme.textPrimary)
                    if strokes > 0 {
                        ForEach(0..<strokes, id: \.self) { _ in
                            Circle().fill(Theme.primaryGreen).frame(width: 6, height: 6)
                        }
                    }
                }
                Text("HCP: \(player.courseHandicap)").font(.caption).foregroundStyle(Theme.textSecondary)
            }

            Spacer()

            if let score = existing, score.grossScore > 0 {
                let st = vm.scoreType(gross: score.grossScore, par: vm.currentHolePar)
                VStack(spacing: 2) {
                    Text("\(score.grossScore)").font(.title2.bold()).foregroundStyle(st.color)
                    Text("Net: \(score.netScore)").font(.caption).foregroundStyle(Theme.textSecondary)
                    Text(st.rawValue).font(.caption2).foregroundStyle(st.color)
                }
            }

            // Quick score buttons
            HStack(spacing: 4) {
                ForEach(quickScores, id: \.self) { s in
                    Button {
                        vm.setScore(playerId: player.playerId, grossScore: s, modelContext: modelContext)
                    } label: {
                        Text("\(s)").font(.caption.bold())
                            .frame(width: 32, height: 32)
                            .background(existing?.grossScore == s ? Theme.primaryGreen : Theme.lightGreen)
                            .foregroundStyle(existing?.grossScore == s ? .white : Theme.textPrimary)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .cardStyle()
    }

    private var quickScores: [Int] {
        let par = vm.currentHolePar
        return Array((par - 1)...(par + 3))
    }
}
