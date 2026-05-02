import Foundation

/// In-memory snapshot of the signed-in user. Persisted via `KeychainHelper`.
struct AuthSession: Equatable {
    let userID: String
    let displayName: String
    let email: String?
    let identityToken: String

    var initials: String {
        let parts = displayName.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? ""
        let last  = parts.dropFirst().first?.first.map(String.init) ?? ""
        let combined = (first + last).uppercased()
        return combined.isEmpty ? "?" : combined
    }
}
