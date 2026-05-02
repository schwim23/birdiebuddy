import XCTest

final class AuthTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testSignInLinkVisibleOnHomeWhenSignedOut() {
        XCTAssertTrue(app.buttons["auth.signInLink"].waitForExistence(timeout: 3))
    }

    func testTappingSignInLinkOpensSignInScreen() {
        let link = app.buttons["auth.signInLink"]
        XCTAssertTrue(link.waitForExistence(timeout: 3))
        link.tap()
        XCTAssertTrue(app.buttons["auth.signInWithAppleButton"].waitForExistence(timeout: 3))
    }
}
