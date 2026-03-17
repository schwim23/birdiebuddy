import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @State private var navigateToRound = false

    var body: some View {
        VStack(spacing: 32) {
            Text("Birdie Buddy")
                .font(.largeTitle)
                .fontWeight(.bold)

            Button("Start Round") {
                appState.startRound()
                navigateToRound = true
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
        .navigationDestination(isPresented: $navigateToRound) {
            RoundView(navigateToRound: $navigateToRound)
        }
    }
}
