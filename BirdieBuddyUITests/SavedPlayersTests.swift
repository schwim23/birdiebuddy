import XCTest

final class SavedPlayersTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Helpers

    private func goToSetup() {
        app.buttons["home.startRoundButton"].tap()
        XCTAssertTrue(app.textFields["setup.playerNameField"].waitForExistence(timeout: 2))
    }

    private func addPlayer(name: String) {
        let field = app.textFields["setup.playerNameField"]
        field.tap()
        field.typeText(name)
        app.buttons["setup.addPlayerConfirmButton"].tap()
    }

    private func navigateBackToHome() {
        // SetupView has a navigation back button (does not hide it)
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.buttons["home.startRoundButton"].waitForExistence(timeout: 2))
    }

    // MARK: - Tests

    /// Add a player in setup, go back to home, re-enter setup — the player should appear
    /// in the Saved Players collapsible section (only shown when savedProfiles is non-empty).
    func testAddedPlayerAppearsInSavedPlayers() {
        goToSetup()
        addPlayer(name: "Saved Person")

        // Go back without starting a round — SwiftData save happens on addPlayer
        navigateBackToHome()
        goToSetup()

        // The "Saved Players" section should now be visible
        let savedPlayersButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Saved Players'")).firstMatch
        XCTAssertTrue(savedPlayersButton.waitForExistence(timeout: 2))
        savedPlayersButton.tap()

        XCTAssertTrue(app.staticTexts["Saved Person"].waitForExistence(timeout: 2))
    }

    func testSavedPlayerCanBeAddedToNewRound() {
        goToSetup()
        addPlayer(name: "Returning Player")
        navigateBackToHome()
        goToSetup()

        let savedPlayersButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Saved Players'")).firstMatch
        XCTAssertTrue(savedPlayersButton.waitForExistence(timeout: 2))
        savedPlayersButton.tap()

        XCTAssertTrue(app.staticTexts["Returning Player"].waitForExistence(timeout: 2))
        // Tap Add next to the saved player
        app.buttons["Add"].firstMatch.tap()

        // Start round button should now be enabled
        XCTAssertTrue(app.buttons["setup.startRoundButton"].isEnabled)
    }
}
