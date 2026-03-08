
import SwiftUI
import SwiftData

struct PairingEditorScreen: View {
    @Bindable var viewModel: TournamentViewModel
    let modelContext: ModelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    if let round = viewModel.editingRound {
                        Text("Round \(round.roundNumber) Pairings")
                            .font(.headline)
                            .foregroundStyle(Theme.textPrimary)
                    }

                    Button {
                        viewModel.shufflePairings()
                    } label: {
                        Label("Shuffle All", systemImage: "shuffle")
                            .secondaryButtonStyle()
                    }

                    ForEach(Array(viewModel.pairingDraft.enumerated()), id: \.offset) { groupIndex, group in
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Group \(groupIndex + 1)")
                                .font(.subheadline.bold())
                                .foregroundStyle(Theme.primaryGreen)

                            ForEach(Array(group.enumerated()), id: \.element.id) { playerIndex, slot in
                                HStack {
                                    Image(systemName: "line.3.horizontal")
                                        .foregroundStyle(Theme.textSecondary)
                                    Circle()
                                        .fill(Theme.primaryGreen.opacity(0.2))
                                        .frame(width: 28, height: 28)
                                        .overlay {
                                            Text("\(playerIndex + 1)")
                                                .font(.caption.bold())
                                                .foregroundStyle(Theme.primaryGreen)
                                        }
                                    Text(slot.playerName.isEmpty ? "Empty" : slot.playerName)
                                        .font(.subheadline)
                                        .foregroundStyle(slot.playerName.isEmpty ? Theme.textSecondary : Theme.textPrimary)
                                    Spacer()
                                    if let pid = slot.playerId {
                                        let tp = viewModel.tournament.players.first { $0.playerId == pid }
                                        Text("HCP: \(String(format: "%.1f", tp?.handicapIndex ?? 0))")
                                            .font(.caption)
                                            .foregroundStyle(Theme.textSecondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .cardStyle()
                    }

                    Button {
                        viewModel.savePairings(modelContext: modelContext)
                        dismiss()
                    } label: {
                        Text("Save Pairings")
                            .primaryButtonStyle()
                    }

                    Spacer(minLength: 40)
                }
                .padding()
            }
        }
        .navigationTitle("Edit Pairings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    viewModel.showPairingEditor = false
                    dismiss()
                }
            }
        }
    }
}
