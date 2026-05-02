import SwiftUI

/// Enter a 6-char join code, see the session, add yourself as a player,
/// and drop into the live round.
struct JoinRoundView: View {
    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router

    @State private var code: String = ""
    @State private var session: RoundSessionDTO?
    @State private var firstGroup: RoundGroupDTO?
    @State private var existingPlayers: [SessionPlayerDTO] = []
    @State private var name: String = ""
    @State private var handicap: Int = 0
    @State private var isWorking = false
    @State private var error: String?

    var body: some View {
        Form {
            Section("Code") {
                TextField("6-character join code", text: $code)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled(true)
                    .accessibilityIdentifier("join.codeField")

                Button {
                    Task { await lookup() }
                } label: {
                    HStack {
                        Spacer()
                        if isWorking { ProgressView() }
                        else { Text("Find Round").fontWeight(.semibold) }
                        Spacer()
                    }
                }
                .disabled(code.count != 6 || isWorking)
                .accessibilityIdentifier("join.findButton")
            }

            if let session, let firstGroup {
                Section(session.courseName) {
                    Text("Format: \(session.format)")
                    Text("Players in group:")
                    ForEach(existingPlayers) { p in
                        Text("• \(p.name) (\(p.handicap))")
                    }
                }

                Section("You") {
                    TextField("Name", text: $name)
                        .accessibilityIdentifier("join.nameField")
                    Stepper("Handicap: \(handicap)", value: $handicap, in: 0...54)
                    Button {
                        Task { await join(group: firstGroup, session: session) }
                    } label: {
                        HStack {
                            Spacer()
                            Text("Join Round").fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(name.isEmpty || isWorking)
                    .accessibilityIdentifier("join.joinButton")
                }
            }

            if let error {
                Text(error).font(.caption).foregroundStyle(.red)
            }
        }
        .navigationTitle("Join Round")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if name.isEmpty, let n = appState.authSession?.displayName, !n.isEmpty {
                name = n
            }
        }
    }

    private func lookup() async {
        isWorking = true
        defer { isWorking = false }
        do {
            guard let s = try await appState.cloudKit.fetchSession(code: code.uppercased()) else {
                error = "No round found for that code."
                return
            }
            let groups = try await appState.cloudKit.fetchGroups(in: s.id)
            guard let g = groups.first else {
                error = "Round has no groups yet."
                return
            }
            let players = try await appState.cloudKit.fetchPlayers(in: g.id)
            session = s
            firstGroup = g
            existingPlayers = players
            error = nil
        } catch {
            self.error = "Lookup failed. Check your connection."
        }
    }

    private func join(group: RoundGroupDTO, session: RoundSessionDTO) async {
        isWorking = true
        defer { isWorking = false }
        do {
            let userID = (try? await appState.cloudKit.currentUserRecordID())
                ?? appState.authSession?.userID
            _ = try await appState.cloudKit.addPlayer(
                name: name, handicap: handicap, userRecordID: userID,
                role: "player", to: group.id
            )
            try? await appState.cloudKit.subscribe(toSession: session.id)

            appState.liveSession = LiveSessionContext(
                sessionID: session.id, roundGroupID: group.id,
                joinCode: session.code, isCreator: false
            )
            appState.startRound(
                with: [Player(name: name, handicap: handicap)],
                format: GameFormat(rawValue: session.format) ?? .strokePlay
            )
            router.navigate(to: .round)
        } catch {
            self.error = "Could not join. Try again."
        }
    }
}
