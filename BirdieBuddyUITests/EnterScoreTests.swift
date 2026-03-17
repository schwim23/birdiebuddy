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

    private func startRound() {
        app.buttons["home.startRoundButton"].tap()
        XCTAssertTrue(app.staticTexts["round.holeLabel"].waitForExistence(timeout: 2))
    }

    func testEnterScoreAdvancesHole() {
        startRound()

        app.buttons["round.scoreButton.5"].tap()

        let holeLabel = app.staticTexts["round.holeLabel"]
        XCTAssertTrue(holeLabel.waitForExistence(timeout: 2))
        XCTAssertEqual(holeLabel.label, "Hole 2")
    }

    func testAllScoreButtonsExist() {
        startRound()

        for score in 3...10 {
            let button = app.buttons["round.scoreButton.\(score)"]
            XCTAssertTrue(button.exists, "Score button \(score) should exist")
        }
    }

    func testPlayThrough18HolesShowsSummary() {
        startRound()

        for hole in 1...18 {
            let holeLabel = app.staticTexts["round.holeLabel"]
            XCTAssertTrue(holeLabel.waitForExistence(timeout: 3), "Hole \(hole) label not found")

            app.buttons["round.scoreButton.5"].tap()
        }

        let summaryLabel = app.staticTexts["summary.totalScoreLabel"]
        XCTAssertTrue(summaryLabel.waitForExistence(timeout: 3), "Summary screen should appear after 18 holes")
        XCTAssertEqual(summaryLabel.label, "90") // 18 holes × 5 strokes
    }
}
