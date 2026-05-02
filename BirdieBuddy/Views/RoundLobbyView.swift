import SwiftUI

/// Create a new collaborative round (single group, Phase 1) and push it to
/// CloudKit. Once created, transitions into the regular RoundView with
/// `liveSession` set so scoring mirrors to the cloud.
struct RoundLobbyView: View {
    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router

    @State private var courseName: String = ""
    @State private var format: GameFormat = .strokePlay
    @State private var creatorName: String = ""
    @State private var creatorHandicap: Int = 0
    @State private var isCreating = false
    @State private var error: String?

    var body: some View {
        Form {
            Section("Course") {
                TextField("Course name", text: $courseName)
                    .accessibilityIdentifier("lobby.courseName")
            }

            Section("Format") {
                Picker("Format", selection: $format) {
                    ForEach(GameFormat.allCases, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }
                .pickerStyle(.menu)
                .accessibilityIdentifier("lobby.formatPicker")
            }

            Section("Your Player") {
                TextField("Name", text: $creatorName)
                    .accessibilityIdentifier("lobby.creatorName")
                Stepper("Handicap: \(creatorHandicap)", value: $creatorHandicap, in: 0...54)
            }

            Section {
                Button {
                    Task { await createSession() }
                } label: {
                    HStack {
                        Spacer()
                        if isCreating {
                            ProgressView()
                        } else {
                            Text("Create Live Round").fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .disabled(courseName.isEmpty || creatorName.isEmpty || isCreating)
                .accessibilityIdentifier("lobby.createButton")

                if let error {
                    Text(error).font(.caption).foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("New Live Round")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if creatorName.isEmpty,
               let name = appState.authSession?.displayName,
               !name.isEmpty {
                creatorName = name
            }
        }
    }

    private func createSession() async {
        isCreating = true
        defer { isCreating = false }
        do {
            let userID = (try? await appState.cloudKit.currentUserRecordID())
                ?? appState.authSession?.userID
                ?? "anonymous"
            let session = try await appState.cloudKit.createSession(
                courseName: courseName,
                courseID: nil,
                format: format.rawValue,
                scheduledTeeTime: nil,
                creatorUserRecordID: userID
            )
            let group = try await appState.cloudKit.createGroup(in: session.id, index: 0)
            _ = try await appState.cloudKit.addPlayer(
                name: creatorName, handicap: creatorHandicap,
                userRecordID: userID, role: "creator", to: group.id
            )
            try? await appState.cloudKit.subscribe(toSession: session.id)

            appState.liveSession = LiveSessionContext(
                sessionID: session.id, roundGroupID: group.id,
                joinCode: session.code, isCreator: true
            )
            appState.startRound(
                with: [Player(name: creatorName, handicap: creatorHandicap)],
                format: format
            )
            router.navigate(to: .round)
        } catch {
            self.error = "Could not create round. Check iCloud sign-in and try again."
        }
    }
}
