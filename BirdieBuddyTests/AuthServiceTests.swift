import Testing
import Foundation
@testable import BirdieBuddy

@Suite("AuthService persistence", .serialized)
struct AuthServiceTests {
    private let svc = AuthService.shared

    init() { svc.signOut() }      // start clean

    @Test("first sign-in persists and round-trips")
    func firstSignIn() {
        let session = svc.signIn(userID: "u-1",
                                 nameFromApple: "Mike Schwimmer",
                                 emailFromApple: "m@example.com",
                                 identityToken: "tok-1")
        #expect(session.userID == "u-1")
        #expect(session.displayName == "Mike Schwimmer")
        #expect(session.email == "m@example.com")
        #expect(session.identityToken == "tok-1")

        let restored = svc.restoreSession()
        #expect(restored == session)
        svc.signOut()
    }

    @Test("Apple omits name on subsequent sign-ins; we keep the saved one")
    func nameMergedFromKeychain() {
        _ = svc.signIn(userID: "u-2", nameFromApple: "Mike Schwimmer",
                       emailFromApple: "m@x.com", identityToken: "tok-a")
        let next = svc.signIn(userID: "u-2", nameFromApple: nil,
                              emailFromApple: nil, identityToken: "tok-b")
        #expect(next.displayName == "Mike Schwimmer")
        #expect(next.email == "m@x.com")
        #expect(next.identityToken == "tok-b")  // token does refresh
        svc.signOut()
    }

    @Test("signOut clears the keychain")
    func signOutClears() {
        _ = svc.signIn(userID: "u-3", nameFromApple: "Tester",
                       emailFromApple: "t@x.com", identityToken: "tok-c")
        svc.signOut()
        #expect(svc.restoreSession() == nil)
    }

    @Test("restore returns nil when nothing was saved")
    func restoreEmpty() {
        svc.signOut()
        #expect(svc.restoreSession() == nil)
    }
}
