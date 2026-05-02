import Foundation
@testable import BirdieBuddy

/// In-memory implementation of `CloudKitServiceProtocol` for unit tests.
/// Operations execute synchronously inside the async wrapper — no real
/// network or container is touched.
final class MockCloudKitService: CloudKitServiceProtocol, @unchecked Sendable {

    var sessions: [String: RoundSessionDTO] = [:]
    var groups:   [String: RoundGroupDTO] = [:]
    var players:  [String: SessionPlayerDTO] = [:]
    var scores:   [String: ScoreEntryDTO] = [:]
    var subscribedSessionIDs: Set<String> = []
    var stubUserRecordID: String = "mock-user-id"

    func fetchSession(code: String) async throws -> RoundSessionDTO? {
        sessions.values.first { $0.code == code }
    }

    func createSession(courseName: String, courseID: String?, format: String,
                       scheduledTeeTime: Date?, creatorUserRecordID: String) async throws -> RoundSessionDTO {
        let id = UUID().uuidString
        let session = RoundSessionDTO(
            id: id,
            code: CloudKitService.makeJoinCode(),
            creatorUserRecordID: creatorUserRecordID,
            courseName: courseName,
            courseID: courseID,
            format: format,
            scheduledTeeTime: scheduledTeeTime,
            status: CKSchema.SessionStatus.lobby,
            createdAt: Date()
        )
        sessions[id] = session
        return session
    }

    func addPlayer(name: String, handicap: Int, userRecordID: String?, role: String,
                   to roundGroupID: String) async throws -> SessionPlayerDTO {
        let player = SessionPlayerDTO(
            id: UUID().uuidString,
            roundGroupID: roundGroupID,
            name: name,
            handicap: handicap,
            userRecordID: userRecordID,
            role: role
        )
        players[player.id] = player
        return player
    }

    func saveScore(playerName: String, hole: Int, strokes: Int,
                   in roundGroupID: String) async throws -> ScoreEntryDTO {
        let entry = ScoreEntryDTO(
            id: UUID().uuidString,
            roundGroupID: roundGroupID,
            playerName: playerName,
            hole: hole,
            strokes: strokes,
            recordedAt: Date()
        )
        scores[entry.id] = entry
        return entry
    }

    func fetchScores(in roundGroupID: String) async throws -> [ScoreEntryDTO] {
        scores.values
            .filter { $0.roundGroupID == roundGroupID }
            .sorted { $0.recordedAt < $1.recordedAt }
    }

    func subscribe(toSession sessionID: String) async throws {
        subscribedSessionIDs.insert(sessionID)
    }

    func currentUserRecordID() async throws -> String {
        stubUserRecordID
    }
}
