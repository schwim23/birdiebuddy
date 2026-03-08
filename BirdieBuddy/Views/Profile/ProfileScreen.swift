
import SwiftUI
import SwiftData

struct ProfileScreen: View {
    @Environment(AppState.self) private var appState
    @Environment(AuthService.self) private var authService
    @Environment(\.modelContext) private var modelContext
    @State private var showSettings = false
    @State private var editingName = false
    @State private var editingHandicap = false
    @State private var newName = ""
    @State private var newHandicap = ""

    @Query(sort: \GolfRound.date, order: .reverse) private var allRounds: [GolfRound]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Profile header
                        VStack(spacing: 16) {
                            Circle()
                                .fill(Theme.primaryGreen.opacity(0.2))
                                .frame(width: 80, height: 80)
                                .overlay {
                                    Text(initials)
                                        .font(.title.bold())
                                        .foregroundStyle(Theme.primaryGreen)
                                }

                            VStack(spacing: 4) {
                                if editingName {
                                    HStack {
                                        TextField("Name", text: $newName)
                                            .textFieldStyle(.roundedBorder)
                                            .frame(width: 200)
                                        Button("Save") {
                                            appState.currentUser?.displayName = newName
                                            UserDefaults.standard.set(newName, forKey: "userName")
                                            editingName = false
                                        }
                                        .font(.caption.bold())
                                        .foregroundStyle(Theme.primaryGreen)
                                    }
                                } else {
                                    HStack(spacing: 8) {
                                        Text(appState.currentUser?.displayName ?? "Golfer")
                                            .font(.title2.bold())
                                            .foregroundStyle(Theme.textPrimary)
                                        Button {
                                            newName = appState.currentUser?.displayName ?? ""
                                            editingName = true
                                        } label: {
                                            Image(systemName: "pencil.circle")
                                                .foregroundStyle(Theme.primaryGreen)
                                        }
                                    }
                                }

                                if let email = appState.currentUser?.email {
                                    Text(email)
                                        .font(.caption)
                                        .foregroundStyle(Theme.textSecondary)
                                }
                            }
                        }
                        .padding()

                        // Handicap
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Label("Handicap Index", systemImage: "number.circle")
                                    .font(.headline)
                                    .foregroundStyle(Theme.textPrimary)
                                Spacer()
                                if editingHandicap {
                                    HStack {
                                        TextField("HCP", text: $newHandicap)
                                            .textFieldStyle(.roundedBorder)
                                            .keyboardType(.decimalPad)
                                            .frame(width: 80)
                                        Button("Save") {
                                            let hcp = Double(newHandicap) ?? 0
                                            appState.currentUser?.handicapIndex = hcp
                                            UserDefaults.standard.set(hcp, forKey: "userHandicap")
                                            editingHandicap = false
                                        }
                                        .font(.caption.bold())
                                        .foregroundStyle(Theme.primaryGreen)
                                    }
                                } else {
                                    HStack(spacing: 8) {
                                        Text(String(format: "%.1f", appState.currentUser?.handicapIndex ?? 0))
                                            .font(.title.bold())
                                            .foregroundStyle(Theme.primaryGreen)
                                        Button {
                                            newHandicap = String(format: "%.1f", appState.currentUser?.handicapIndex ?? 0)
                                            editingHandicap = true
                                        } label: {
                                            Image(systemName: "pencil.circle")
                                                .foregroundStyle(Theme.primaryGreen)
                                        }
                                    }
                                }
                            }
                        }
                        .cardStyle()

                        // Stats
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Stats", systemImage: "chart.bar.fill")
                                .font(.headline)
                                .foregroundStyle(Theme.textPrimary)

                            let completedRounds = allRounds.filter { $0.roundStatus == .completed }
                            HStack(spacing: 20) {
                                StatBox(label: "Rounds", value: "\(completedRounds.count)")
                                StatBox(label: "18-Hole", value: "\(completedRounds.filter { $0.holeCount == 18 }.count)")
                                StatBox(label: "9-Hole", value: "\(completedRounds.filter { $0.holeCount == 9 }.count)")
                            }
                        }
                        .cardStyle()

                        // Round History
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Round History", systemImage: "clock")
                                .font(.headline)
                                .foregroundStyle(Theme.textPrimary)

                            let completed = allRounds.filter { $0.roundStatus == .completed }
                            if completed.isEmpty {
                                Text("No completed rounds yet.")
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                            } else {
                                ForEach(completed.prefix(10)) { round in
                                    NavigationLink {
                                        RoundSummaryScreen(round: round)
                                    } label: {
                                        HStack {
                                            Text(round.course?.name ?? "Unknown")
                                                .font(.subheadline)
                                                .foregroundStyle(Theme.textPrimary)
                                            Spacer()
                                            Text(round.date.shortFormatted)
                                                .font(.caption)
                                                .foregroundStyle(Theme.textSecondary)
                                        }
                                    }
                                    Divider()
                                }
                            }
                        }
                        .cardStyle()

                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink {
                        SettingsScreen()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
        }
    }

    private var initials: String {
        let name = appState.currentUser?.displayName ?? "G"
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}

private struct StatBox: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(Theme.primaryGreen)
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}
