import AuthenticationServices
import SwiftUI

/// Full-screen sign-in for unauthenticated entry points (e.g. "Start Live Round").
struct SignInView: View {
    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router
    @Environment(\.colorScheme) private var colorScheme
    @State private var error: String?

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "person.crop.circle.badge.checkmark")
                    .font(.system(size: 56))
                    .foregroundStyle(.green)
                Text("Sign in to Birdie Buddy")
                    .font(.title2).fontWeight(.semibold)
                Text("Required for live rounds and tournaments. Solo rounds work without an account.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                handle(result)
            }
            .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
            .frame(height: 50)
            .padding(.horizontal, 32)
            .accessibilityIdentifier("auth.signInWithAppleButton")

            if let error {
                Text(error)
                    .font(.caption).foregroundStyle(.red)
                    .padding(.horizontal, 32)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .navigationTitle("Sign In")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func handle(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else {
                error = "Unsupported credential type."
                return
            }
            do {
                let session = try AuthService.shared.signIn(with: credential)
                appState.authSession = session
                router.pop()
            } catch {
                self.error = "Sign-in failed. Please try again."
            }
        case .failure(let err):
            // ASAuthorizationError.canceled is silent
            if (err as NSError).code != ASAuthorizationError.canceled.rawValue {
                error = "Sign-in failed. Please try again."
            }
        }
    }
}
