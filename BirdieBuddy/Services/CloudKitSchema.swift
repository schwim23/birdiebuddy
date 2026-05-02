import Foundation

/// String constants matching the CloudKit Dashboard schema declared in
/// docs/features/d10-cloudkit-setup.md. Centralised here so a typo in a
/// record-type or field name fails at one site rather than at the call site.
enum CKSchema {

    enum RoundSession {
        static let recordType = "RoundSession"
        static let code                  = "code"
        static let creatorUserRecordID   = "creatorUserRecordID"
        static let courseName            = "courseName"
        static let courseID              = "courseID"
        static let format                = "format"
        static let scheduledTeeTime      = "scheduledTeeTime"
        static let status                = "status"
        static let createdAt             = "createdAt"
    }

    enum RoundGroup {
        static let recordType = "RoundGroup"
        static let roundSessionRef = "roundSessionRef"
        static let groupIndex      = "groupIndex"
    }

    enum SessionPlayer {
        static let recordType = "SessionPlayer"
        static let roundGroupRef = "roundGroupRef"
        static let name          = "name"
        static let handicap      = "handicap"
        static let userRecordID  = "userRecordID"
        static let role          = "role"
    }

    enum ScoreEntry {
        static let recordType = "ScoreEntry"
        static let roundGroupRef = "roundGroupRef"
        static let playerName    = "playerName"
        static let hole          = "hole"
        static let strokes       = "strokes"
        static let recordedAt    = "recordedAt"
    }

    /// Status values for `RoundSession.status`.
    enum SessionStatus {
        static let lobby     = "lobby"
        static let active    = "active"
        static let completed = "completed"
    }
}
