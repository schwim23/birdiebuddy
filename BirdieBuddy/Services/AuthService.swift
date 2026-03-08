
import SwiftUI
import AuthenticationServices

@MainActor
@Observable
final class AuthService {
    var isSignedIn: Bool = false
    var currentUser: UserProfile?
    var errorMessage: String?

    func signInWithApple(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            if let credential = auth.credential as? ASAuthorizationAppleIDCredential {
                let userId = credential.user
                let fullName = [credential.fullName?.givenName, credential.fullName?.familyName]
                    .compactMap { $0 }.joined(separator: " ")
                let email = credential.email
                let user = UserProfile(
                    displayName: fullName.isEmpty ? "Golfer" : fullName,
                    email: email,
                    handicapIndex: 0.0
                )
                UserDefaults.standard.set(userId, forKey: "appleUserId")
                UserDefaults.standard.set(user.displayName, forKey: "userName")
                UserDefaults.standard.set(user.handicapIndex, forKey: "userHandicap")
                currentUser = user
                isSignedIn = true
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    func signInWithGoogle() {
        // TODO: Integrate GoogleSignIn SDK via SPM for production
        errorMessage = "Google Sign-In coming soon. Please use Apple or Guest."
    }

    func continueAsGuest(name: String, handicap: Double) {
        let user = UserProfile(displayName: name, email: nil, handicapIndex: handicap)
        currentUser = user
        isSignedIn = true
        UserDefaults.standard.set(true, forKey: "isGuest")
        UserDefaults.standard.set(name, forKey: "userName")
        UserDefaults.standard.set(handicap, forKey: "userHandicap")
    }

    func signOut() {
        isSignedIn = false
        currentUser = nil
        UserDefaults.standard.removeObject(forKey: "appleUserId")
        UserDefaults.standard.removeObject(forKey: "isGuest")
        UserDefaults.standard.removeObject(forKey: "userName")
        UserDefaults.standard.removeObject(forKey: "userHandicap")
    }
}
