import Foundation

/// Plain-Swift mirrors of the CloudKit record types. All CloudKit access
/// goes through `CloudKitService` and returns these — no `CKRecord` leaks
/// out to the UI layer.

struct RoundSessionDTO: Equatable, Identifiable {
    let id: String                 // CKRecord.ID.recordName
    let code: String               // 6-char join code
    let creatorUserRecordID: String
    let courseName: String
    let courseID: String?
    let format: String             // GameFormat raw value
    let scheduledTeeTime: Date?
    var status: String             // SessionStatus.*
    let createdAt: Date
}

struct RoundGroupDTO: Equatable, Identifiable {
    let id: String
    let roundSessionID: String
    let groupIndex: Int
}

struct SessionPlayerDTO: Equatable, Identifiable {
    let id: String
    let roundGroupID: String
    let name: String
    let handicap: Int
    let userRecordID: String?
    let role: String               // "creator" | "player"
}

struct ScoreEntryDTO: Equatable, Identifiable {
    let id: String
    let roundGroupID: String
    let playerName: String
    let hole: Int
    let strokes: Int
    let recordedAt: Date
}
