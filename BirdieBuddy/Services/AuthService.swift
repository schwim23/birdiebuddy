import AuthenticationServices
import Foundation

/// Owns the Sign-in-with-Apple flow and Keychain-backed session persistence.
/// Stateless aside from the in-memory `currentSession` snapshot — `AppState`
/// holds the published authoritative copy.
final class AuthService {
    static let shared = AuthService()

    private enum Key {
        static let userID = "auth.userID"
        static let displayName = "auth.displayName"
        static let email = "auth.email"
        static let identityToken = "auth.identityToken"
    }

    enum SignInError: Error {
        case missingIdentityToken
        case unsupportedCredentialType
    }

    /// Builds an `AuthSession` from a fresh Apple credential and persists it.
    func signIn(with credential: ASAuthorizationAppleIDCredential) throws -> AuthSession {
        guard let tokenData = credential.identityToken,
              let token = String(data: tokenData, encoding: .utf8) else {
            throw SignInError.missingIdentityToken
        }
        let nameFromApple = [credential.fullName?.givenName, credential.fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")
        return signIn(userID: credential.user,
                      nameFromApple: nameFromApple.isEmpty ? nil : nameFromApple,
                      emailFromApple: credential.email,
                      identityToken: token)
    }

    /// Persistence-only sign-in — testable. Apple only sends `fullName` / `email`
    /// on the *first* sign-in for a given user ID, so we merge with the keychain.
    func signIn(userID: String, nameFromApple: String?, emailFromApple: String?,
                identityToken: String) -> AuthSession {
        let displayName = nameFromApple ?? KeychainHelper.read(Key.displayName) ?? ""
        let email = emailFromApple ?? KeychainHelper.read(Key.email)

        KeychainHelper.save(userID, for: Key.userID)
        KeychainHelper.save(displayName, for: Key.displayName)
        KeychainHelper.save(identityToken, for: Key.identityToken)
        if let email { KeychainHelper.save(email, for: Key.email) }

        return AuthSession(userID: userID, displayName: displayName,
                           email: email, identityToken: identityToken)
    }

    /// Reads a previously persisted session, if one exists.
    func restoreSession() -> AuthSession? {
        guard let userID = KeychainHelper.read(Key.userID),
              let token  = KeychainHelper.read(Key.identityToken) else { return nil }
        return AuthSession(
            userID: userID,
            displayName: KeychainHelper.read(Key.displayName) ?? "",
            email: KeychainHelper.read(Key.email),
            identityToken: token
        )
    }

    /// Validates a previously persisted session against Apple's credential state.
    /// Returns false when the user has revoked the app from Settings → Apple ID.
    func validateSession(userID: String) async -> Bool {
        let provider = ASAuthorizationAppleIDProvider()
        return await withCheckedContinuation { cont in
            provider.getCredentialState(forUserID: userID) { state, _ in
                cont.resume(returning: state == .authorized)
            }
        }
    }

    func signOut() {
        KeychainHelper.delete(Key.userID)
        KeychainHelper.delete(Key.displayName)
        KeychainHelper.delete(Key.email)
        KeychainHelper.delete(Key.identityToken)
    }
}
