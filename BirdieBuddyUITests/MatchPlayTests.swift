import XCTest

final class MatchPlayTests: XCTestCase {
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

    // MARK: - Tests

    func testFormatPickerHiddenWithOnePlayer() {
        goToSetup()
        addPlayer(name: "Alice")
        XCTAssertFalse(app.otherElements["setup.formatPicker"].exists)
    }

    func testFormatPickerVisibleWithTwoPlayers() {
        goToSetup()
        addPlayer(name: "Alice")
        addPlayer(name: "Bob")
        XCTAssertTrue(app.segmentedControls["setup.formatPicker"].waitForExistence(timeout: 2))
    }

    func testMatchStatusLabelExistsDuringMatchPlayRound() {
        goToSetup()
        addPlayer(name: "Alice")
        addPlayer(name: "Bob")

        let picker = app.segmentedControls["setup.formatPicker"]
        XCTAssertTrue(picker.waitForExistence(timeout: 2))
        picker.buttons["Match Play"].tap()

        app.buttons["setup.startRoundButton"].tap()
        XCTAssertTrue(app.staticTexts["round.matchStatusLabel"].waitForExistence(timeout: 3))
    }

    func testMatchStatusStartsAsAllSquare() {
        goToSetup()
        addPlayer(name: "Alice")
        addPlayer(name: "Bob")

        let picker = app.segmentedControls["setup.formatPicker"]
        XCTAssertTrue(picker.waitForExistence(timeout: 2))
        picker.buttons["Match Play"].tap()

        app.buttons["setup.startRoundButton"].tap()
        let statusLabel = app.staticTexts["round.matchStatusLabel"]
        XCTAssertTrue(statusLabel.waitForExistence(timeout: 3))
        XCTAssertEqual(statusLabel.label, "All Square")
    }

    func testMatchResultLabelShownOnSummary() {
        goToSetup()
        addPlayer(name: "Alice")
        addPlayer(name: "Bob")

        let picker = app.segmentedControls["setup.formatPicker"]
        XCTAssertTrue(picker.waitForExistence(timeout: 2))
        picker.buttons["Match Play"].tap()
        app.buttons["setup.startRoundButton"].tap()

        XCTAssertTrue(app.staticTexts["round.holeLabel"].waitForExistence(timeout: 3))

        // Match play can end early once the match is decided — loop until summary appears
        for _ in 1...18 {
            if app.staticTexts["summary.matchResultLabel"].exists { break }
            guard app.staticTexts["round.holeLabel"].waitForExistence(timeout: 3) else { break }
            let f0 = app.textFields["round.scoreField.0"]
            let f1 = app.textFields["round.scoreField.1"]
            if f0.waitForExistence(timeout: 3) { f0.tap(); f0.typeText("4") }
            if f1.waitForExistence(timeout: 3) { f1.tap(); f1.typeText("5") }
        }

        XCTAssertTrue(app.staticTexts["summary.matchResultLabel"].waitForExistence(timeout: 6))
    }
}
