
import SwiftUI
import AuthenticationServices

struct AuthScreen: View {
    @Environment(AppState.self) private var appState
    @Environment(AuthService.self) private var authService
    @State private var guestName = ""
    @State private var guestHandicap = ""
    @State private var showGuestForm = false
    @State private var showError = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 32) {
                    Spacer().frame(height: 60)
                    VStack(spacing: 12) {
                        Image(systemName: "figure.golf").font(.system(size: 70)).foregroundStyle(Theme.primaryGreen)
                        Text("BirdieBuddy").font(.system(size: 34, weight: .bold, design: .rounded)).foregroundStyle(Theme.darkGreen)
                        Text("Track scores, play games, share shots").font(.subheadline).foregroundStyle(Theme.textSecondary)
                    }
                    Spacer().frame(height: 20)
                    VStack(spacing: 16) {
                        SignInWithAppleButton(.signIn) { request in
                            request.requestedScopes = [.fullName, .email]
                        } onCompletion: { result in
                            Task { @MainActor in
                                authService.signInWithApple(result: result)
                                if authService.isSignedIn, let user = authService.currentUser { appState.signIn(user: user) }
                                if authService.errorMessage != nil { showError = true }
                            }
                        }
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))

                        Button {
                            authService.signInWithGoogle()
                            if authService.errorMessage != nil { showError = true }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "globe").font(.title3)
                                Text("Sign in with Google").font(.headline)
                            }
                            .foregroundStyle(.white).frame(maxWidth: .infinity).frame(height: 50)
                            .background(Color(red: 0.26, green: 0.52, blue: 0.96))
                            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
                        }

                        HStack {
                            Rectangle().fill(Theme.textSecondary.opacity(0.3)).frame(height: 1)
                            Text("or").foregroundStyle(Theme.textSecondary).font(.caption)
                            Rectangle().fill(Theme.textSecondary.opacity(0.3)).frame(height: 1)
                        }.padding(.vertical, 8)

                        if showGuestForm {
                            VStack(spacing: 12) {
                                TextField("Your Name", text: $guestName).textFieldStyle(.roundedBorder).autocorrectionDisabled()
                                TextField("Handicap (optional)", text: $guestHandicap).textFieldStyle(.roundedBorder).keyboardType(.decimalPad)
                                Button {
                                    authService.continueAsGuest(name: guestName.isEmpty ? "Golfer" : guestName, handicap: Double(guestHandicap) ?? 0)
                                    if let u = authService.currentUser { appState.signIn(user: u) }
                                } label: { Text("Start Playing").primaryButtonStyle() }
                            }.cardStyle()
                        } else {
                            Button { withAnimation { showGuestForm = true } } label: { Text("Continue as Guest").secondaryButtonStyle() }
                        }
                    }.padding(.horizontal, 24)
                    Spacer()
                }
            }
        }
        .alert("Sign In Error", isPresented: $showError) { Button("OK"){} } message: { Text(authService.errorMessage ?? "Unknown error") }
    }
}
