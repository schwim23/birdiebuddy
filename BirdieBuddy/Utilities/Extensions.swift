
import SwiftUI

extension View {
    func cardStyle() -> some View {
        self.padding(Theme.cardPadding)
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    func primaryButtonStyle() -> some View {
        self.font(.headline).foregroundStyle(.white).frame(maxWidth: .infinity)
            .padding(.vertical, 14).background(Theme.primaryGreen)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
    }
    func secondaryButtonStyle() -> some View {
        self.font(.headline).foregroundStyle(Theme.primaryGreen).frame(maxWidth: .infinity)
            .padding(.vertical, 14).background(Theme.lightGreen)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
    }
}

extension Date {
    var shortFormatted: String {
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .none; return f.string(from: self)
    }
}
