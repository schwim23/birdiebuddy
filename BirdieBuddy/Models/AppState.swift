
import SwiftUI
import Foundation

@MainActor
@Observable
final class AppState {
    var isLoading: Bool = true
    var isAuthenticated: Bool = false
    var currentUser: UserProfile?

    func checkAuthStatus(authService: AuthService) async {
        try? await Task.sleep(nanoseconds: 1_500_000_000)

        let hasAppleId = UserDefaults.standard.string(forKey: "appleUserId") != nil
        let isGuest = UserDefaults.standard.bool(forKey: "isGuest")
        let savedName = UserDefaults.standard.string(forKey: "userName") ?? "Golfer"
        let savedHandicap = UserDefaults.standard.double(forKey: "userHandicap")

        if hasAppleId || isGuest {
            let user = UserProfile(
                displayName: savedName,
                email: nil,
                handicapIndex: savedHandicap,
                createdAt: Date()
            )
            authService.currentUser = user
            authService.isSignedIn = true
            currentUser = user
            isAuthenticated = true
        } else {
            isAuthenticated = false
        }

        isLoading = false
    }

    func signIn(user: UserProfile) {
        currentUser = user
        isAuthenticated = true
    }

    func signOut() {
        currentUser = nil
        isAuthenticated = false
    }
}
