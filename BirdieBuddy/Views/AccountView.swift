import SwiftUI

/// Sheet shown when the user taps the avatar in HomeView. Displays identity
/// details and the Sign-Out action.
struct AccountView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if let session = appState.authSession {
                    avatar(session: session)

                    VStack(spacing: 4) {
                        Text(session.displayName.isEmpty ? "Signed in" : session.displayName)
                            .font(.title3).fontWeight(.semibold)
                            .accessibilityIdentifier("auth.displayName")
                        if let email = session.email {
                            Text(email)
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    Button(role: .destructive) {
                        AuthService.shared.signOut()
                        appState.authSession = nil
                        dismiss()
                    } label: {
                        Text("Sign Out")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .padding(.horizontal)
                    .accessibilityIdentifier("auth.signOutButton")
                } else {
                    Text("Not signed in")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 32)
            .padding(.bottom, 24)
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func avatar(session: AuthSession) -> some View {
        Circle()
            .fill(Color.green.opacity(0.18))
            .frame(width: 84, height: 84)
            .overlay(
                Text(session.initials)
                    .font(.title.weight(.semibold))
                    .foregroundStyle(.green)
            )
    }
}
