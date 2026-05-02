import Foundation

/// Identifies an in-progress collaborative round so the rest of the app
/// (notably `AppState.recordScore`) can mirror local scoring to CloudKit.
struct LiveSessionContext: Equatable {
    let sessionID: String
    let roundGroupID: String
    let joinCode: String
    let isCreator: Bool
}
