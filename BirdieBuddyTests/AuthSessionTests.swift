import Testing
import Foundation
@testable import BirdieBuddy

@Suite("AuthSession.initials")
struct AuthSessionInitialsTests {
    private func session(_ name: String) -> AuthSession {
        AuthSession(userID: "x", displayName: name, email: nil, identityToken: "t")
    }

    @Test("first + last name produces two-letter initials")
    func twoNames() {
        #expect(session("Mike Schwimmer").initials == "MS")
    }

    @Test("single name produces one-letter initials")
    func singleName() {
        #expect(session("Mike").initials == "M")
    }

    @Test("three names use first and second")
    func threeNames() {
        #expect(session("Mike Christopher Schwimmer").initials == "MC")
    }

    @Test("empty name falls back to '?'")
    func emptyName() {
        #expect(session("").initials == "?")
    }

    @Test("lowercase name is uppercased")
    func lowercaseUppercased() {
        #expect(session("mike schwimmer").initials == "MS")
    }
}
