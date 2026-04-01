import XCTest

final class MultiPlayerTests: XCTestCase {
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

    private func startRoundWithTwoPlayers() {
        goToSetup()
        addPlayer(name: "Alice")
        addPlayer(name: "Bob")
        app.buttons["setup.startRoundButton"].tap()
        XCTAssertTrue(app.staticTexts["round.holeLabel"].waitForExistence(timeout: 3))
    }

    // MARK: - Tests

    func testAddTwoPlayersShowsBothInSetup() {
        goToSetup()
        addPlayer(name: "Alice")
        addPlayer(name: "Bob")
        XCTAssertTrue(app.staticTexts["Alice"].exists)
        XCTAssertTrue(app.staticTexts["Bob"].exists)
    }

    func testTwoPlayersShowScoreFieldsInRound() {
        startRoundWithTwoPlayers()
        XCTAssertTrue(app.textFields["round.scoreField.0"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.textFields["round.scoreField.1"].exists)
    }

    func testHoleAdvancesOnlyAfterAllPlayersScore() {
        startRoundWithTwoPlayers()

        // Enter score for first player only
        let field0 = app.textFields["round.scoreField.0"]
        XCTAssertTrue(field0.waitForExistence(timeout: 2))
        field0.tap()
        field0.typeText("5")

        // Hole should still be 1
        let holeLabel = app.staticTexts["round.holeLabel"]
        XCTAssertEqual(holeLabel.label, "Hole 1")

        // Enter score for second player
        let field1 = app.textFields["round.scoreField.1"]
        field1.tap()
        field1.typeText("4")

        // Now hole should advance
        XCTAssertTrue(holeLabel.waitForExistence(timeout: 3))
        XCTAssertEqual(holeLabel.label, "Hole 2")
    }

    func testSummaryShowsAllPlayersAfterFullRound() {
        startRoundWithTwoPlayers()

        for hole in 1...18 {
            XCTAssertTrue(app.staticTexts["round.holeLabel"].waitForExistence(timeout: 3), "Missing hole label at hole \(hole)")
            let f0 = app.textFields["round.scoreField.0"]
            let f1 = app.textFields["round.scoreField.1"]
            XCTAssertTrue(f0.waitForExistence(timeout: 3))
            f0.tap(); f0.typeText("5")
            XCTAssertTrue(f1.waitForExistence(timeout: 3))
            f1.tap(); f1.typeText("4")
        }

        XCTAssertTrue(app.staticTexts["summary.totalScoreLabel"].waitForExistence(timeout: 6))
        // Both player names should appear in the summary
        XCTAssertTrue(app.staticTexts["Alice"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Bob"].exists)
    }
}
