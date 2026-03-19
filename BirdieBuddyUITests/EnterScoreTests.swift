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

    /// Enters a score for the first player's score field on the current hole.
    private func enterScore(_ score: Int) {
        let field = app.textFields["round.scoreField.0"]
        XCTAssertTrue(field.waitForExistence(timeout: 3))
        field.tap()
        field.typeText("\(score)")
    }

    // MARK: - Tests

    func testScoreFieldExistsForPlayer() {
        startRound()
        XCTAssertTrue(app.textFields["round.scoreField.0"].waitForExistence(timeout: 2))
    }

    func testEnterScoreAdvancesHole() {
        startRound()
        enterScore(5)

        let holeLabel = app.staticTexts["round.holeLabel"]
        XCTAssertTrue(holeLabel.waitForExistence(timeout: 3))
        XCTAssertEqual(holeLabel.label, "Hole 2")
    }

    func testPlayThrough18HolesShowsSummary() {
        startRound()

        for hole in 1...18 {
            XCTAssertTrue(app.staticTexts["round.holeLabel"].waitForExistence(timeout: 3), "Hole \(hole) label not found")
            enterScore(5)
        }

        let summaryLabel = app.staticTexts["summary.totalScoreLabel"]
        XCTAssertTrue(summaryLabel.waitForExistence(timeout: 6))
        XCTAssertEqual(summaryLabel.label, "90") // 18 × 5
    }
}
