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
        let startButton = app.buttons["home.startRoundButton"]
        XCTAssertTrue(startButton.exists, "Start Round button should be visible on home screen")
    }

    func testTapStartRoundShowsHole1() {
        app.buttons["home.startRoundButton"].tap()

        let holeLabel = app.staticTexts["round.holeLabel"]
        XCTAssertTrue(holeLabel.waitForExistence(timeout: 2))
        XCTAssertEqual(holeLabel.label, "Hole 1")
    }

    func testHole1ShowsPar4() {
        app.buttons["home.startRoundButton"].tap()

        let parLabel = app.staticTexts["round.parLabel"]
        XCTAssertTrue(parLabel.waitForExistence(timeout: 2))
        XCTAssertEqual(parLabel.label, "Par 4")
    }
}
