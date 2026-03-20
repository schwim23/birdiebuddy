import SwiftUI

private let kLabelWidth: CGFloat  = 76
private let kHoleWidth: CGFloat   = 36
private let kSubtotalWidth: CGFloat = 48
private let kRowHeight: CGFloat   = 44

struct ScorecardView: View {
    @Environment(AppState.self) private var appState

    private let frontNine = Array(1...9)
    private let backNine  = Array(10...18)

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            VStack(spacing: 0) {
                holeHeaderRow
                parRow
                Divider()
                ForEach(appState.players, id: \.id) { player in
                    playerRow(player)
                    if player.id != appState.players.last?.id {
                        Divider()
                    }
                }
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.systemGray4), lineWidth: 0.5))
            .padding()
        }
        .accessibilityIdentifier("scorecard.grid")
        .navigationTitle("Scorecard")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header row (hole numbers)

    private var holeHeaderRow: some View {
        HStack(spacing: 0) {
            cell("Hole", width: kLabelWidth, font: .caption.weight(.semibold), color: .secondary)
            ForEach(frontNine, id: \.self) { hole in
                cell("\(hole)", width: kHoleWidth, font: .caption.weight(.semibold), color: .secondary)
            }
            cell("OUT", width: kSubtotalWidth, font: .caption.weight(.bold), color: .secondary)
            ForEach(backNine, id: \.self) { hole in
                cell("\(hole)", width: kHoleWidth, font: .caption.weight(.semibold), color: .secondary)
            }
            cell("IN",  width: kSubtotalWidth, font: .caption.weight(.bold), color: .secondary)
            cell("TOT", width: kSubtotalWidth, font: .caption.weight(.bold), color: .secondary)
        }
        .frame(height: kRowHeight)
        .background(Color(.systemGray6))
    }

    // MARK: - Par row

    private var parRow: some View {
        HStack(spacing: 0) {
            cell("Par", width: kLabelWidth, font: .caption.weight(.semibold), color: .secondary)
            ForEach(frontNine, id: \.self) { hole in
                cell("\(Course.defaultPar[hole] ?? 4)", width: kHoleWidth, font: .caption, color: .secondary)
            }
            let frontPar = frontNine.reduce(0) { $0 + (Course.defaultPar[$1] ?? 4) }
            cell("\(frontPar)", width: kSubtotalWidth, font: .caption.weight(.semibold), color: .secondary)
            ForEach(backNine, id: \.self) { hole in
                cell("\(Course.defaultPar[hole] ?? 4)", width: kHoleWidth, font: .caption, color: .secondary)
            }
            let backPar = backNine.reduce(0) { $0 + (Course.defaultPar[$1] ?? 4) }
            cell("\(backPar)", width: kSubtotalWidth, font: .caption.weight(.semibold), color: .secondary)
            let totalPar = frontPar + backPar
            cell("\(totalPar)", width: kSubtotalWidth, font: .caption.weight(.bold), color: .secondary)
        }
        .frame(height: kRowHeight)
    }

    // MARK: - Player row

    private func playerRow(_ player: Player) -> some View {
        let frontScore = frontNine.compactMap { appState.score(for: player, hole: $0) }.reduce(0, +)
        let frontPlayed = frontNine.filter { appState.score(for: player, hole: $0) != nil }.count
        let backScore  = backNine.compactMap  { appState.score(for: player, hole: $0) }.reduce(0, +)
        let backPlayed = backNine.filter  { appState.score(for: player, hole: $0) != nil }.count

        return HStack(spacing: 0) {
            // Name
            Text(player.name)
                .font(.subheadline).fontWeight(.medium)
                .lineLimit(1)
                .frame(width: kLabelWidth, height: kRowHeight)
                .padding(.horizontal, 4)

            // Front nine
            ForEach(frontNine, id: \.self) { hole in
                scoreCell(player: player, hole: hole)
            }

            // OUT
            subtotalCell(score: frontScore, played: frontPlayed)

            // Back nine
            ForEach(backNine, id: \.self) { hole in
                scoreCell(player: player, hole: hole)
            }

            // IN
            subtotalCell(score: backScore, played: backPlayed)

            // TOT
            subtotalCell(score: frontScore + backScore, played: frontPlayed + backPlayed)
        }
        .frame(height: kRowHeight)
    }

    // MARK: - Score cell

    private func scoreCell(player: Player, hole: Int) -> some View {
        let strokes = appState.score(for: player, hole: hole)
        let par = Course.defaultPar[hole] ?? 4
        let category = strokes.map { ScoreCategory.category(for: $0, par: par) }

        return ZStack {
            if let cat = category, cat != .par {
                cat.color.opacity(cat == .eagle ? 1.0 : 0.85)
            }
            if let s = strokes {
                Text("\(s)")
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundStyle(category == .par ? Color.primary : Color.white)
            } else {
                Text("–")
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
            }
        }
        .frame(width: kHoleWidth, height: kRowHeight)
        .accessibilityIdentifier("scorecard.cell.\(player.name).\(hole)")
    }

    // MARK: - Subtotal cell

    private func subtotalCell(score: Int, played: Int) -> some View {
        Text(played > 0 ? "\(score)" : "–")
            .font(.subheadline).fontWeight(.bold)
            .foregroundStyle(played > 0 ? .primary : .secondary)
            .frame(width: kSubtotalWidth, height: kRowHeight)
            .background(Color(.systemGray6))
    }

    // MARK: - Generic cell

    private func cell(_ text: String, width: CGFloat, font: Font, color: Color) -> some View {
        Text(text)
            .font(font)
            .foregroundStyle(color)
            .frame(width: width, height: kRowHeight)
    }
}
