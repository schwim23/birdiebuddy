import XCTest

final class EnterScoreTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Helper

    /// Navigates through home + setup into RoundView with one player.
    private func startRound() {
        app.buttons["home.startRoundButton"].tap()
        XCTAssertTrue(app.textFields["setup.playerNameField"].waitForExistence(timeout: 2))

        let nameField = app.textFields["setup.playerNameField"]
        nameField.tap()
        nameField.typeText("Test Player")

        app.buttons["setup.addPlayerConfirmButton"].tap()
        app.buttons["setup.startRoundButton"].tap()

        XCTAssertTrue(app.staticTexts["round.holeLabel"].waitForExistence(timeout: 2))
    }

    // MARK: - Tests

    func testEnterScoreAdvancesHole() {
        startRound()

        app.buttons["round.scoreButton.5"].tap()

        let holeLabel = app.staticTexts["round.holeLabel"]
        XCTAssertTrue(holeLabel.waitForExistence(timeout: 2))
        XCTAssertEqual(holeLabel.label, "Hole 2")
    }

    func testAllScoreButtonsExist() {
        startRound()
        for score in 1...9 {
            XCTAssertTrue(app.buttons["round.scoreButton.\(score)"].exists, "Score button \(score) missing")
        }
    }

    func testPlayThrough18HolesShowsSummary() {
        startRound()

        for hole in 1...18 {
            XCTAssertTrue(app.staticTexts["round.holeLabel"].waitForExistence(timeout: 3), "Hole \(hole) label not found")
            app.buttons["round.scoreButton.5"].tap()
        }

        let summaryLabel = app.staticTexts["summary.totalScoreLabel"]
        XCTAssertTrue(summaryLabel.waitForExistence(timeout: 6))
        XCTAssertEqual(summaryLabel.label, "90") // 18 × 5
    }
}
