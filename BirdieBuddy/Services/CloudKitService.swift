import CloudKit
import Foundation

/// Operations the rest of the app needs from CloudKit. The protocol exists
/// so feature 013 can be unit-tested against an in-memory `MockCloudKitService`
/// without requiring a configured iCloud container.
protocol CloudKitServiceProtocol {
    /// Look up a session by its 6-char join code.
    func fetchSession(code: String) async throws -> RoundSessionDTO?

    /// Create a new RoundSession + initial RoundGroup. Returns the session.
    func createSession(courseName: String, courseID: String?, format: String,
                       scheduledTeeTime: Date?, creatorUserRecordID: String) async throws -> RoundSessionDTO

    /// Create a RoundGroup under a session.
    func createGroup(in sessionID: String, index: Int) async throws -> RoundGroupDTO

    /// Append a SessionPlayer to a group.
    func addPlayer(name: String, handicap: Int, userRecordID: String?, role: String,
                   to roundGroupID: String) async throws -> SessionPlayerDTO

    /// All groups under a session, ordered by groupIndex.
    func fetchGroups(in sessionID: String) async throws -> [RoundGroupDTO]

    /// All players in a group.
    func fetchPlayers(in roundGroupID: String) async throws -> [SessionPlayerDTO]

    /// Append (or overwrite) a player's score for a hole.
    func saveScore(playerName: String, hole: Int, strokes: Int,
                   in roundGroupID: String) async throws -> ScoreEntryDTO

    /// Pull every score entry for a group, oldest-first.
    func fetchScores(in roundGroupID: String) async throws -> [ScoreEntryDTO]

    /// Subscribe to score / player changes for a session so the device receives
    /// silent pushes on insert/update. Idempotent — safe to re-call.
    func subscribe(toSession sessionID: String) async throws

    /// CloudKit's stable user record ID for the signed-in iCloud account.
    /// Throws if iCloud is not signed in.
    func currentUserRecordID() async throws -> String
}

/// Production implementation that talks to the public database of
/// `iCloud.com.schwim23.birdiebuddy`. The container ID is read from the
/// `iCloud` entitlement at runtime.
final class CloudKitService: CloudKitServiceProtocol {
    static let shared = CloudKitService()

    private let container: CKContainer
    private var db: CKDatabase { container.publicCloudDatabase }

    init(container: CKContainer = .default()) {
        self.container = container
    }

    // MARK: - Session

    func fetchSession(code: String) async throws -> RoundSessionDTO? {
        let predicate = NSPredicate(format: "%K == %@", CKSchema.RoundSession.code, code)
        let query = CKQuery(recordType: CKSchema.RoundSession.recordType, predicate: predicate)
        let (matches, _) = try await db.records(matching: query, resultsLimit: 1)
        guard let (_, result) = matches.first else { return nil }
        let record = try result.get()
        return Self.session(from: record)
    }

    func createSession(courseName: String, courseID: String?, format: String,
                       scheduledTeeTime: Date?, creatorUserRecordID: String) async throws -> RoundSessionDTO {
        let record = CKRecord(recordType: CKSchema.RoundSession.recordType)
        let code = Self.makeJoinCode()
        record[CKSchema.RoundSession.code]                = code as CKRecordValue
        record[CKSchema.RoundSession.creatorUserRecordID] = creatorUserRecordID as CKRecordValue
        record[CKSchema.RoundSession.courseName]          = courseName as CKRecordValue
        if let courseID { record[CKSchema.RoundSession.courseID] = courseID as CKRecordValue }
        record[CKSchema.RoundSession.format]              = format as CKRecordValue
        if let scheduledTeeTime {
            record[CKSchema.RoundSession.scheduledTeeTime] = scheduledTeeTime as CKRecordValue
        }
        record[CKSchema.RoundSession.status]    = CKSchema.SessionStatus.lobby as CKRecordValue
        record[CKSchema.RoundSession.createdAt] = Date() as CKRecordValue

        let saved = try await db.save(record)
        // First RoundGroup is created lazily by the first joining client.
        return Self.session(from: saved)
    }

    // MARK: - Groups

    func createGroup(in sessionID: String, index: Int) async throws -> RoundGroupDTO {
        let record = CKRecord(recordType: CKSchema.RoundGroup.recordType)
        let sessionRef = CKRecord.Reference(recordID: .init(recordName: sessionID), action: .deleteSelf)
        record[CKSchema.RoundGroup.roundSessionRef] = sessionRef
        record[CKSchema.RoundGroup.groupIndex]      = index as CKRecordValue
        let saved = try await db.save(record)
        return RoundGroupDTO(id: saved.recordID.recordName, roundSessionID: sessionID, groupIndex: index)
    }

    func fetchGroups(in sessionID: String) async throws -> [RoundGroupDTO] {
        let sessionRef = CKRecord.Reference(recordID: .init(recordName: sessionID), action: .none)
        let predicate = NSPredicate(format: "%K == %@", CKSchema.RoundGroup.roundSessionRef, sessionRef)
        let query = CKQuery(recordType: CKSchema.RoundGroup.recordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: CKSchema.RoundGroup.groupIndex, ascending: true)]
        let (matches, _) = try await db.records(matching: query)
        return matches.compactMap {
            guard let r = try? $0.1.get() else { return nil }
            return RoundGroupDTO(
                id: r.recordID.recordName,
                roundSessionID: sessionID,
                groupIndex: r[CKSchema.RoundGroup.groupIndex] as? Int ?? 0
            )
        }
    }

    func fetchPlayers(in roundGroupID: String) async throws -> [SessionPlayerDTO] {
        let groupRef = CKRecord.Reference(recordID: .init(recordName: roundGroupID), action: .none)
        let predicate = NSPredicate(format: "%K == %@", CKSchema.SessionPlayer.roundGroupRef, groupRef)
        let query = CKQuery(recordType: CKSchema.SessionPlayer.recordType, predicate: predicate)
        let (matches, _) = try await db.records(matching: query)
        return matches.compactMap {
            guard let r = try? $0.1.get() else { return nil }
            return SessionPlayerDTO(
                id: r.recordID.recordName,
                roundGroupID: roundGroupID,
                name:     r[CKSchema.SessionPlayer.name] as? String ?? "",
                handicap: r[CKSchema.SessionPlayer.handicap] as? Int ?? 0,
                userRecordID: r[CKSchema.SessionPlayer.userRecordID] as? String,
                role:     r[CKSchema.SessionPlayer.role] as? String ?? "player"
            )
        }
    }

    // MARK: - Players & scores

    func addPlayer(name: String, handicap: Int, userRecordID: String?, role: String,
                   to roundGroupID: String) async throws -> SessionPlayerDTO {
        let record = CKRecord(recordType: CKSchema.SessionPlayer.recordType)
        let groupRef = CKRecord.Reference(recordID: .init(recordName: roundGroupID), action: .deleteSelf)
        record[CKSchema.SessionPlayer.roundGroupRef] = groupRef
        record[CKSchema.SessionPlayer.name]     = name as CKRecordValue
        record[CKSchema.SessionPlayer.handicap] = handicap as CKRecordValue
        record[CKSchema.SessionPlayer.role]     = role as CKRecordValue
        if let userRecordID { record[CKSchema.SessionPlayer.userRecordID] = userRecordID as CKRecordValue }
        let saved = try await db.save(record)
        return SessionPlayerDTO(
            id: saved.recordID.recordName,
            roundGroupID: roundGroupID,
            name: name,
            handicap: handicap,
            userRecordID: userRecordID,
            role: role
        )
    }

    func saveScore(playerName: String, hole: Int, strokes: Int,
                   in roundGroupID: String) async throws -> ScoreEntryDTO {
        let record = CKRecord(recordType: CKSchema.ScoreEntry.recordType)
        let groupRef = CKRecord.Reference(recordID: .init(recordName: roundGroupID), action: .deleteSelf)
        let recordedAt = Date()
        record[CKSchema.ScoreEntry.roundGroupRef] = groupRef
        record[CKSchema.ScoreEntry.playerName]    = playerName as CKRecordValue
        record[CKSchema.ScoreEntry.hole]          = hole as CKRecordValue
        record[CKSchema.ScoreEntry.strokes]       = strokes as CKRecordValue
        record[CKSchema.ScoreEntry.recordedAt]    = recordedAt as CKRecordValue
        let saved = try await db.save(record)
        return ScoreEntryDTO(
            id: saved.recordID.recordName,
            roundGroupID: roundGroupID,
            playerName: playerName,
            hole: hole,
            strokes: strokes,
            recordedAt: recordedAt
        )
    }

    func fetchScores(in roundGroupID: String) async throws -> [ScoreEntryDTO] {
        let groupRef = CKRecord.Reference(recordID: .init(recordName: roundGroupID), action: .none)
        let predicate = NSPredicate(format: "%K == %@", CKSchema.ScoreEntry.roundGroupRef, groupRef)
        let query = CKQuery(recordType: CKSchema.ScoreEntry.recordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: CKSchema.ScoreEntry.recordedAt, ascending: true)]
        let (matches, _) = try await db.records(matching: query)
        return matches.compactMap { try? Self.score(from: $0.1.get()) }
    }

    // MARK: - Subscriptions

    func subscribe(toSession sessionID: String) async throws {
        let groupRef = CKRecord.Reference(recordID: .init(recordName: sessionID), action: .none)
        let predicate = NSPredicate(format: "%K == %@", CKSchema.RoundGroup.roundSessionRef, groupRef)
        let scoreSub = CKQuerySubscription(
            recordType: CKSchema.ScoreEntry.recordType,
            predicate: predicate,
            subscriptionID: "scores-\(sessionID)",
            options: [.firesOnRecordCreation, .firesOnRecordUpdate]
        )
        let info = CKSubscription.NotificationInfo()
        info.shouldSendContentAvailable = true   // silent push
        scoreSub.notificationInfo = info

        let playerSub = CKQuerySubscription(
            recordType: CKSchema.SessionPlayer.recordType,
            predicate: predicate,
            subscriptionID: "players-\(sessionID)",
            options: [.firesOnRecordCreation]
        )
        playerSub.notificationInfo = info

        // CKModifySubscriptionsOperation tolerates duplicate subscription IDs
        // by replacing them — this makes subscribe(...) idempotent.
        let op = CKModifySubscriptionsOperation(
            subscriptionsToSave: [scoreSub, playerSub],
            subscriptionIDsToDelete: nil
        )
        op.qualityOfService = .userInitiated
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            op.modifySubscriptionsResultBlock = { result in
                switch result {
                case .success:        cont.resume()
                case .failure(let e): cont.resume(throwing: e)
                }
            }
            db.add(op)
        }
    }

    // MARK: - User identity

    func currentUserRecordID() async throws -> String {
        let id = try await container.userRecordID()
        return id.recordName
    }

    // MARK: - Helpers

    private static func session(from record: CKRecord) -> RoundSessionDTO {
        RoundSessionDTO(
            id: record.recordID.recordName,
            code: record[CKSchema.RoundSession.code] as? String ?? "",
            creatorUserRecordID: record[CKSchema.RoundSession.creatorUserRecordID] as? String ?? "",
            courseName: record[CKSchema.RoundSession.courseName] as? String ?? "",
            courseID:   record[CKSchema.RoundSession.courseID] as? String,
            format:     record[CKSchema.RoundSession.format] as? String ?? "",
            scheduledTeeTime: record[CKSchema.RoundSession.scheduledTeeTime] as? Date,
            status:     record[CKSchema.RoundSession.status] as? String ?? CKSchema.SessionStatus.lobby,
            createdAt:  record[CKSchema.RoundSession.createdAt] as? Date ?? .distantPast
        )
    }

    private static func score(from record: CKRecord) -> ScoreEntryDTO {
        ScoreEntryDTO(
            id: record.recordID.recordName,
            roundGroupID: (record[CKSchema.ScoreEntry.roundGroupRef] as? CKRecord.Reference)?
                .recordID.recordName ?? "",
            playerName: record[CKSchema.ScoreEntry.playerName] as? String ?? "",
            hole:       record[CKSchema.ScoreEntry.hole] as? Int ?? 0,
            strokes:    record[CKSchema.ScoreEntry.strokes] as? Int ?? 0,
            recordedAt: record[CKSchema.ScoreEntry.recordedAt] as? Date ?? .distantPast
        )
    }

    /// 6-character A–Z 0–9 join code. Collisions are checked at insert time
    /// in feature 013; with ~2 billion combinations they are extremely rare.
    static func makeJoinCode() -> String {
        let chars = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")  // omit 0/O/1/I
        return String((0..<6).map { _ in chars.randomElement()! })
    }
}
