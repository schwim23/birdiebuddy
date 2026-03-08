
import SwiftUI

struct LaunchScreen: View {
    @State private var scale: Double = 0.8
    @State private var opacity: Double = 0.0

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "figure.golf")
                    .font(.system(size: 80))
                    .foregroundStyle(Theme.primaryGreen)
                Text("BirdieBuddy")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.darkGreen)
                Text("Your Golf Companion")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                ProgressView().tint(Theme.primaryGreen).padding(.top, 20)
            }
            .scaleEffect(scale).opacity(opacity)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) { scale = 1.0; opacity = 1.0 }
        }
    }
}
