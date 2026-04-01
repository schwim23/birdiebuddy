import XCTest

final class ScorecardTests: XCTestCase {
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

    private func startRound() {
        app.buttons["home.startRoundButton"].tap()
        XCTAssertTrue(app.textFields["setup.playerNameField"].waitForExistence(timeout: 2))
        let field = app.textFields["setup.playerNameField"]
        field.tap()
        field.typeText("Test Player")
        app.buttons["setup.addPlayerConfirmButton"].tap()
        app.buttons["setup.startRoundButton"].tap()
        XCTAssertTrue(app.staticTexts["round.holeLabel"].waitForExistence(timeout: 3))
    }

    // MARK: - Tests

    func testScorecardButtonExistsInRound() {
        startRound()
        XCTAssertTrue(app.buttons["round.scorecardButton"].exists)
    }

    func testScorecardButtonNavigatesToGrid() {
        startRound()
        app.buttons["round.scorecardButton"].tap()
        XCTAssertTrue(app.scrollViews["scorecard.grid"].waitForExistence(timeout: 3))
    }

    func testScorecardGridShowsAfterSomeScores() {
        startRound()

        // Enter scores for first 3 holes
        for _ in 1...3 {
            let field = app.textFields["round.scoreField.0"]
            XCTAssertTrue(field.waitForExistence(timeout: 3))
            field.tap()
            field.typeText("5")
            XCTAssertTrue(app.staticTexts["round.holeLabel"].waitForExistence(timeout: 3))
        }

        app.buttons["round.scorecardButton"].tap()
        XCTAssertTrue(app.scrollViews["scorecard.grid"].waitForExistence(timeout: 3))
    }
}
