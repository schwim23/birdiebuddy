import Testing
import Foundation
@testable import BirdieBuddy

@Suite("AppState live-session score push")
struct LiveSessionTests {

    private func setup() -> (AppState, MockCloudKitService) {
        let svc = MockCloudKitService()
        let state = AppState()
        state.cloudKit = svc
        return (state, svc)
    }

    @Test("pushScoreToCloud no-ops when not in a live session")
    func noOpWhenSolo() async throws {
        let (state, svc) = setup()
        let mike = Player(name: "Mike", handicap: 0)
        let result = try await state.pushScoreToCloud(4, hole: 1, player: mike)
        #expect(result == nil)
        #expect(svc.scores.isEmpty)
    }

    @Test("pushScoreToCloud writes to the bound group when live")
    func pushesWhenLive() async throws {
        let (state, svc) = setup()
        state.liveSession = LiveSessionContext(
            sessionID: "s-1", roundGroupID: "g-1", joinCode: "ABC123", isCreator: true
        )
        let mike = Player(name: "Mike", handicap: 12)
        let entry = try await state.pushScoreToCloud(5, hole: 7, player: mike)
        #expect(entry?.playerName == "Mike")
        #expect(entry?.hole == 7)
        #expect(entry?.strokes == 5)
        #expect(entry?.roundGroupID == "g-1")
        #expect(svc.scores.values.count == 1)
    }
}

@Suite("Live session lobby + join (mock)")
struct LiveSessionFlowTests {

    @Test("createSession + createGroup + addPlayer + fetchSession by code matches")
    func createAndFindByCode() async throws {
        let svc = MockCloudKitService()
        let session = try await svc.createSession(
            courseName: "Pebble Beach", courseID: nil, format: "strokePlay",
            scheduledTeeTime: nil, creatorUserRecordID: "u-1"
        )
        let group = try await svc.createGroup(in: session.id, index: 0)
        _ = try await svc.addPlayer(name: "Mike", handicap: 12, userRecordID: "u-1",
                                     role: "creator", to: group.id)

        let found = try await svc.fetchSession(code: session.code)
        #expect(found?.id == session.id)

        let groups = try await svc.fetchGroups(in: session.id)
        #expect(groups.count == 1)
        #expect(groups.first?.id == group.id)

        let players = try await svc.fetchPlayers(in: group.id)
        #expect(players.count == 1)
        #expect(players.first?.name == "Mike")
    }

    @Test("a second player can join an existing group")
    func secondPlayerJoins() async throws {
        let svc = MockCloudKitService()
        let session = try await svc.createSession(
            courseName: "Pebble", courseID: nil, format: "strokePlay",
            scheduledTeeTime: nil, creatorUserRecordID: "u-1"
        )
        let group = try await svc.createGroup(in: session.id, index: 0)
        _ = try await svc.addPlayer(name: "Mike", handicap: 12, userRecordID: "u-1",
                                     role: "creator", to: group.id)
        _ = try await svc.addPlayer(name: "Joe", handicap: 8, userRecordID: "u-2",
                                     role: "player", to: group.id)
        let players = try await svc.fetchPlayers(in: group.id)
        #expect(Set(players.map(\.name)) == ["Mike", "Joe"])
    }
}
