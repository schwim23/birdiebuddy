import SwiftUI

@main
struct BirdieBuddyApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                HomeView()
            }
            .environment(appState)
        }
    }
}
