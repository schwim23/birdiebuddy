
import SwiftUI

struct GameFormatConfigScreen: View {
    @Binding var selectedFormats: Set<GameFormat>
    let playerCount: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(GameFormat.allCases) { format in
                        let sel = selectedFormats.contains(format)
                        let ok = playerCount >= format.minPlayers
                        Button {
                            if sel { selectedFormats.remove(format) }
                            else if ok { selectedFormats.insert(format) }
                        } label: {
                            HStack {
                                Image(systemName: format.iconName).frame(width: 30)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(format.displayName).font(.subheadline.bold())
                                    Text(format.description).font(.caption).opacity(0.7)
                                    Text("Requires \(format.minPlayers)-\(format.maxPlayers) players").font(.caption2)
                                }
                                Spacer()
                                if sel { Image(systemName: "checkmark.circle.fill") }
                            }
                            .padding()
                            .background(sel ? Theme.primaryGreen : Theme.cardBackground)
                            .foregroundStyle(sel ? .white : (ok ? Theme.textPrimary : Theme.textSecondary))
                            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
                        }.disabled(!ok && !sel)
                    }
                }.padding()
            }
        }
        .navigationTitle("Game Formats").navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
    }
}
