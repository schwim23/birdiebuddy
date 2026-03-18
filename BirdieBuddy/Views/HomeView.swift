import SwiftUI

struct HomeView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        VStack(spacing: 32) {
            Text("Birdie Buddy")
                .font(.largeTitle)
                .fontWeight(.bold)

            Button("Start Round") {
                router.navigate(to: .setup)
            }
            .font(.title2)
            .padding(.horizontal, 40)
            .padding(.vertical, 16)
            .background(Color.green)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .accessibilityIdentifier("home.startRoundButton")
        }
        .navigationTitle("")
        .navigationBarHidden(true)
    }
}
