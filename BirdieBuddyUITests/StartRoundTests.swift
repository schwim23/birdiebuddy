import XCTest

final class StartRoundTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testLaunchShowsStartRoundButton() {
        XCTAssertTrue(app.buttons["home.startRoundButton"].exists)
    }

    func testTapStartRoundNavigatesToSetup() {
        app.buttons["home.startRoundButton"].tap()
        XCTAssertTrue(app.textFields["setup.playerNameField"].waitForExistence(timeout: 2))
    }

    func testSetupAndStartShowsHole1() {
        navigateToRound()
        let holeLabel = app.staticTexts["round.holeLabel"]
        XCTAssertTrue(holeLabel.waitForExistence(timeout: 2))
        XCTAssertEqual(holeLabel.label, "Hole 1")
    }

    func testHole1ShowsPar4() {
        navigateToRound()
        let parLabel = app.staticTexts["round.parLabel"]
        XCTAssertTrue(parLabel.waitForExistence(timeout: 2))
        XCTAssertEqual(parLabel.label, "Par 4")
    }

    // MARK: - Helper

    /// Navigates from home through SetupView and into RoundView with one player added.
    private func navigateToRound() {
        app.buttons["home.startRoundButton"].tap()
        XCTAssertTrue(app.textFields["setup.playerNameField"].waitForExistence(timeout: 2))

        let nameField = app.textFields["setup.playerNameField"]
        nameField.tap()
        nameField.typeText("Test Player")

        app.buttons["setup.addPlayerConfirmButton"].tap()
        app.buttons["setup.startRoundButton"].tap()
    }
}
