import SwiftUI

struct PlayerScoreRow: View {
    let player: Player
    let index: Int
    let hole: Int
    let existingScore: Int?
    let getsStroke: Bool
    var onScore: (Int) -> Void

    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            Text(player.name)
                .font(.body)

            if getsStroke {
                Text("●")
                    .font(.system(size: 10))
                    .foregroundStyle(.primary)
            }

            Spacer()

            TextField("—", text: $text)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.title3.weight(.semibold))
                .frame(width: 52, height: 44)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .focused($isFocused)
                .accessibilityIdentifier("round.scoreField.\(index)")
                .onChange(of: text) { _, val in
                    let digit = String(val.filter { $0.isNumber }.suffix(1))
                    guard let n = Int(digit), (1...9).contains(n) else { return }
                    text = "\(n)"
                    onScore(n)
                }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .onAppear {
            text = existingScore.map { "\($0)" } ?? ""
        }
        .onChange(of: hole) { _, _ in
            text = existingScore.map { "\($0)" } ?? ""
        }
        .onChange(of: existingScore) { _, score in
            text = score.map { "\($0)" } ?? ""
        }
    }
}
