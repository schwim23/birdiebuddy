import Testing
import Foundation
@testable import BirdieBuddy

/// The view itself is hard to assert on without UI tests, but the merge
/// logic — converting flat ScoreEntryDTOs into a `[playerName: [hole: strokes]]`
/// map for the grid — is the part that can regress silently. These tests
/// exercise that contract via the mock service end-to-end.
@Suite("Live scoreboard score aggregation")
struct LiveScoreboardAggregationTests {

    private func setupGroup(_ svc: MockCloudKitService) async throws -> String {
        let session = try await svc.createSession(
            courseName: "Pebble", courseID: nil, format: "strokePlay",
            scheduledTeeTime: nil, creatorUserRecordID: "u-1"
        )
        let group = try await svc.createGroup(in: session.id, index: 0)
        return group.id
    }

    @Test("multiple holes for one player aggregate by hole")
    func singlePlayerMultipleHoles() async throws {
        let svc = MockCloudKitService()
        let groupID = try await setupGroup(svc)
        _ = try await svc.saveScore(playerName: "Mike", hole: 1, strokes: 4, in: groupID)
        _ = try await svc.saveScore(playerName: "Mike", hole: 2, strokes: 5, in: groupID)
        _ = try await svc.saveScore(playerName: "Mike", hole: 3, strokes: 3, in: groupID)

        let scores = try await svc.fetchScores(in: groupID)
        var byPlayer: [String: [Int: Int]] = [:]
        for s in scores { byPlayer[s.playerName, default: [:]][s.hole] = s.strokes }

        #expect(byPlayer["Mike"]?[1] == 4)
        #expect(byPlayer["Mike"]?[2] == 5)
        #expect(byPlayer["Mike"]?[3] == 3)
        #expect((byPlayer["Mike"]?.values.reduce(0, +)) == 12)
    }

    @Test("multiple players segregate cleanly")
    func multiPlayerSegregation() async throws {
        let svc = MockCloudKitService()
        let groupID = try await setupGroup(svc)
        _ = try await svc.saveScore(playerName: "Mike", hole: 1, strokes: 4, in: groupID)
        _ = try await svc.saveScore(playerName: "Joe",  hole: 1, strokes: 5, in: groupID)
        _ = try await svc.saveScore(playerName: "Mike", hole: 2, strokes: 3, in: groupID)

        let scores = try await svc.fetchScores(in: groupID)
        var byPlayer: [String: [Int: Int]] = [:]
        for s in scores { byPlayer[s.playerName, default: [:]][s.hole] = s.strokes }

        #expect(byPlayer["Mike"] == [1: 4, 2: 3])
        #expect(byPlayer["Joe"]  == [1: 5])
    }

    @Test("re-saving the same hole keeps the latest entry")
    func resaveOverwritesGridValue() async throws {
        // The mock appends new ScoreEntries (CloudKit append-only model)
        // and the grid always reads the latest by recordedAt order.
        let svc = MockCloudKitService()
        let groupID = try await setupGroup(svc)
        _ = try await svc.saveScore(playerName: "Mike", hole: 1, strokes: 4, in: groupID)
        try await Task.sleep(nanoseconds: 1_000_000)  // ensure later timestamp
        _ = try await svc.saveScore(playerName: "Mike", hole: 1, strokes: 3, in: groupID)

        let scores = try await svc.fetchScores(in: groupID)
        var byPlayer: [String: [Int: Int]] = [:]
        for s in scores { byPlayer[s.playerName, default: [:]][s.hole] = s.strokes }
        #expect(byPlayer["Mike"]?[1] == 3)
    }

    @Test("empty group returns no scores")
    func emptyGroup() async throws {
        let svc = MockCloudKitService()
        let groupID = try await setupGroup(svc)
        let scores = try await svc.fetchScores(in: groupID)
        #expect(scores.isEmpty)
    }
}
