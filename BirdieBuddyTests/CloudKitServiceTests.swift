import Testing
import Foundation
@testable import BirdieBuddy

@Suite("CloudKitService — join code generation")
struct JoinCodeTests {
    @Test("makeJoinCode produces 6 characters")
    func length() {
        for _ in 0..<50 {
            #expect(CloudKitService.makeJoinCode().count == 6)
        }
    }

    @Test("makeJoinCode avoids visually ambiguous characters")
    func avoidsAmbiguous() {
        let banned: Set<Character> = ["0", "O", "1", "I"]
        for _ in 0..<100 {
            let code = CloudKitService.makeJoinCode()
            for c in code { #expect(!banned.contains(c)) }
        }
    }

    @Test("two consecutive codes are not identical")
    func differs() {
        // Astronomical probability of collision; checking once is fine.
        #expect(CloudKitService.makeJoinCode() != CloudKitService.makeJoinCode())
    }
}

@Suite("MockCloudKitService — happy paths")
struct MockCloudKitFlowTests {
    private func newSvc() -> MockCloudKitService { MockCloudKitService() }

    @Test("create then fetch session by code round-trips")
    func createAndFetch() async throws {
        let svc = newSvc()
        let created = try await svc.createSession(
            courseName: "Pebble Beach", courseID: nil,
            format: "strokePlay", scheduledTeeTime: nil,
            creatorUserRecordID: "u-1"
        )
        let fetched = try await svc.fetchSession(code: created.code)
        #expect(fetched == created)
    }

    @Test("fetchSession returns nil for unknown code")
    func fetchUnknown() async throws {
        let svc = newSvc()
        #expect(try await svc.fetchSession(code: "ZZZZZZ") == nil)
    }

    @Test("addPlayer + saveScore + fetchScores work in order")
    func playerAndScores() async throws {
        let svc = newSvc()
        let group = "g-1"
        _ = try await svc.addPlayer(name: "Mike", handicap: 12, userRecordID: nil,
                                     role: "creator", to: group)
        _ = try await svc.saveScore(playerName: "Mike", hole: 1, strokes: 4, in: group)
        _ = try await svc.saveScore(playerName: "Mike", hole: 2, strokes: 5, in: group)

        let scores = try await svc.fetchScores(in: group)
        #expect(scores.count == 2)
        #expect(scores.map(\.hole) == [1, 2])
    }

    @Test("subscribe records the session id idempotently")
    func subscribeIdempotent() async throws {
        let svc = newSvc()
        try await svc.subscribe(toSession: "s-1")
        try await svc.subscribe(toSession: "s-1")
        #expect(svc.subscribedSessionIDs == ["s-1"])
    }

    @Test("currentUserRecordID returns the stubbed value")
    func userRecordID() async throws {
        let svc = newSvc()
        svc.stubUserRecordID = "abc"
        #expect(try await svc.currentUserRecordID() == "abc")
    }
}
