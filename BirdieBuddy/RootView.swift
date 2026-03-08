
import SwiftUI

struct RootView: View {
    @State private var authService = AuthService()
    @State private var appState = AppState()

    var body: some View {
        Group {
            if appState.isLoading {
                LaunchScreen()
            } else if appState.isAuthenticated {
                MainTabView()
                    .environment(appState)
                    .environment(authService)
            } else {
                AuthScreen()
                    .environment(appState)
                    .environment(authService)
            }
        }
        .task {
            await appState.checkAuthStatus(authService: authService)
        }
    }
}
