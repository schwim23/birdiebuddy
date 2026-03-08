
import SwiftUI

struct SettingsScreen: View {
    @Environment(AppState.self) private var appState
    @Environment(AuthService.self) private var authService
    @AppStorage("useYards") private var useYards = true
    @AppStorage("darkModeOverride") private var darkModeOverride = false
    @State private var showSignOutConfirm = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            List {
                Section("Account") {
                    HStack {
                        Text("Name")
                        Spacer()
                        Text(appState.currentUser?.displayName ?? "Golfer")
                            .foregroundStyle(Theme.textSecondary)
                    }
                    HStack {
                        Text("Email")
                        Spacer()
                        Text(appState.currentUser?.email ?? "Not set")
                            .foregroundStyle(Theme.textSecondary)
                    }
                    HStack {
                        Text("Handicap")
                        Spacer()
                        Text(String(format: "%.1f", appState.currentUser?.handicapIndex ?? 0))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }

                Section("Preferences") {
                    Toggle("Use Yards (vs Meters)", isOn: $useYards)
                    Toggle("Dark Mode", isOn: $darkModeOverride)
                }

                Section("Voice Input") {
                    HStack {
                        Text("Language")
                        Spacer()
                        Text("English (US)")
                            .foregroundStyle(Theme.textSecondary)
                    }
                    NavigationLink("Voice Input Tips") {
                        VoiceTipsScreen()
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(Theme.textSecondary)
                    }
                }

                Section {
                    Button {
                        showSignOutConfirm = true
                    } label: {
                        Text("Sign Out")
                            .foregroundStyle(Theme.destructive)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Sign Out?", isPresented: $showSignOutConfirm) {
            Button("Sign Out", role: .destructive) {
                authService.signOut()
                appState.signOut()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
}

private struct VoiceTipsScreen: View {
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Voice Score Entry Tips")
                        .font(.title2.bold())
                        .foregroundStyle(Theme.textPrimary)

                    TipRow(example: "\"Mike got a birdie\"", explanation: "Records birdie (par - 1) for Mike on the current hole")
                    TipRow(example: "\"Sarah made par\"", explanation: "Records par for Sarah")
                    TipRow(example: "\"John double bogey\"", explanation: "Records double bogey (par + 2) for John")
                    TipRow(example: "\"Lisa got a 5\"", explanation: "Records a score of 5 for Lisa")
                    TipRow(example: "\"Tom eagle\"", explanation: "Records eagle (par - 2) for Tom")
                    TipRow(example: "\"Mike ace\"", explanation: "Records a hole-in-one (1) for Mike")

                    Text("Tips:")
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                        .padding(.top)

                    BulletPoint(text: "Use first names for faster recognition")
                    BulletPoint(text: "Speak clearly and pause briefly between words")
                    BulletPoint(text: "The app will show you what it understood before confirming")
                    BulletPoint(text: "You can always edit scores manually after voice entry")
                }
                .padding()
            }
        }
        .navigationTitle("Voice Tips")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct TipRow: View {
    let example: String
    let explanation: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(example)
                .font(.subheadline.bold())
                .foregroundStyle(Theme.primaryGreen)
            Text(explanation)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
    }
}

private struct BulletPoint: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle().fill(Theme.primaryGreen).frame(width: 6, height: 6).padding(.top, 6)
            Text(text).font(.subheadline).foregroundStyle(Theme.textPrimary)
        }
    }
}
