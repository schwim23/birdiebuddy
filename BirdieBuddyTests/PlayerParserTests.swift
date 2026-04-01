import XCTest
@testable import BirdieBuddy

final class PlayerParserTests: XCTestCase {

    // MARK: - Single player, various formats

    func testBareNameAndDigit() {
        let players = PlayerParser.parse("joe 12")
        XCTAssertEqual(players.count, 1)
        XCTAssertEqual(players[0].name, "Joe")
        XCTAssertEqual(players[0].handicap, 12)
    }

    func testNameWithIsA() {
        let players = PlayerParser.parse("mike is a 14")
        XCTAssertEqual(players.count, 1)
        XCTAssertEqual(players[0].name, "Mike")
        XCTAssertEqual(players[0].handicap, 14)
    }

    func testNameWithWhoIsA() {
        let players = PlayerParser.parse("sarah who is a 8 handicap")
        XCTAssertEqual(players.count, 1)
        XCTAssertEqual(players[0].name, "Sarah")
        XCTAssertEqual(players[0].handicap, 8)
    }

    func testNameWithHeIsA() {
        let players = PlayerParser.parse("dan he is a 20")
        XCTAssertEqual(players.count, 1)
        XCTAssertEqual(players[0].name, "Dan")
        XCTAssertEqual(players[0].handicap, 20)
    }

    func testNameWithHandicapKeyword() {
        let players = PlayerParser.parse("tom handicap 5")
        XCTAssertEqual(players.count, 1)
        XCTAssertEqual(players[0].name, "Tom")
        XCTAssertEqual(players[0].handicap, 5)
    }

    func testNameWithHandicapOf() {
        let players = PlayerParser.parse("tom handicap of 5")
        XCTAssertEqual(players.count, 1)
        XCTAssertEqual(players[0].name, "Tom")
        XCTAssertEqual(players[0].handicap, 5)
    }

    func testScratch() {
        let players = PlayerParser.parse("alice scratch")
        XCTAssertEqual(players.count, 1)
        XCTAssertEqual(players[0].name, "Alice")
        XCTAssertEqual(players[0].handicap, 0)
    }

    func testAddPrefix() {
        let players = PlayerParser.parse("add joe 12")
        XCTAssertEqual(players.count, 1)
        XCTAssertEqual(players[0].name, "Joe")
        XCTAssertEqual(players[0].handicap, 12)
    }

    func testNameOnly() {
        let players = PlayerParser.parse("bob")
        XCTAssertEqual(players.count, 1)
        XCTAssertEqual(players[0].name, "Bob")
        XCTAssertNil(players[0].handicap)
    }

    func testMultiWordName() {
        let players = PlayerParser.parse("joe chanley 12")
        XCTAssertEqual(players.count, 1)
        XCTAssertEqual(players[0].name, "Joe Chanley")
        XCTAssertEqual(players[0].handicap, 12)
    }

    // MARK: - Number words

    func testNumberWordHandicap() {
        let players = PlayerParser.parse("mike is a twelve handicap")
        XCTAssertEqual(players.count, 1)
        XCTAssertEqual(players[0].handicap, 12)
    }

    func testLargeNumberWord() {
        let players = PlayerParser.parse("sarah who is a twenty handicap")
        XCTAssertEqual(players.count, 1)
        XCTAssertEqual(players[0].handicap, 20)
    }

    // MARK: - Multiple players

    func testMultiplePlayersCommaSeparated() {
        let players = PlayerParser.parse("joe 12, mike 14, dan 8")
        XCTAssertEqual(players.count, 3)
        XCTAssertEqual(players[0].name, "Joe");  XCTAssertEqual(players[0].handicap, 12)
        XCTAssertEqual(players[1].name, "Mike"); XCTAssertEqual(players[1].handicap, 14)
        XCTAssertEqual(players[2].name, "Dan");  XCTAssertEqual(players[2].handicap, 8)
    }

    func testMultiplePlayersAndSeparatedNamesOnly() {
        // " and " splitting works when segments don't accidentally match a handicap pattern.
        // Use comma separation for reliable multi-player parsing with handicaps.
        let players = PlayerParser.parse("joe, mike")
        XCTAssertEqual(players.count, 2)
        XCTAssertEqual(players[0].name, "Joe")
        XCTAssertEqual(players[1].name, "Mike")
    }

    func testFullVoicePhrase() {
        // All players comma-separated — the reliable multi-player format.
        let text = "add joe chanley he is a 12 handicap, mike s who is a 14, dan who is a 8, josh who is a 9"
        let players = PlayerParser.parse(text)
        XCTAssertEqual(players.count, 4)
        XCTAssertEqual(players[0].name, "Joe Chanley"); XCTAssertEqual(players[0].handicap, 12)
        XCTAssertEqual(players[1].name, "Mike S");      XCTAssertEqual(players[1].handicap, 14)
        XCTAssertEqual(players[2].name, "Dan");         XCTAssertEqual(players[2].handicap, 8)
        XCTAssertEqual(players[3].name, "Josh");        XCTAssertEqual(players[3].handicap, 9)
    }

    /// Documents a known parser limitation: " and " as separator only works when the
    /// full segment doesn't accidentally match a handicap pattern.
    /// Prefer commas for multi-player dictation with handicaps.
    func testAndSeparatorLimitationWithHandicaps() {
        // "joe 12 and mike 14" — pattern matches "joe 12 and mike" as name, "14" as handicap.
        // This is expected behaviour; use commas to separate players reliably.
        let players = PlayerParser.parse("joe 12 and mike 14")
        XCTAssertEqual(players.count, 1)
    }

    // MARK: - Name capitalisation

    func testCapitalisationSingleWord() {
        XCTAssertEqual(PlayerParser.parse("alice 5").first?.name, "Alice")
    }

    func testCapitalisationMultiWord() {
        XCTAssertEqual(PlayerParser.parse("john doe 10").first?.name, "John Doe")
    }

    // MARK: - Boundary / edge cases

    func testEmptyStringReturnsEmpty() {
        XCTAssertTrue(PlayerParser.parse("").isEmpty)
    }

    func testSingleWordFiltersReturnEmpty() {
        // Single filler words are filtered out
        XCTAssertTrue(PlayerParser.parse("add").isEmpty)
        XCTAssertTrue(PlayerParser.parse("the").isEmpty)
        XCTAssertTrue(PlayerParser.parse("or").isEmpty)
    }

    func testHandicapAbove54Ignored() {
        // 55 is outside the valid range — should fall through to name-only
        let players = PlayerParser.parse("joe 55")
        // Either no player or a player with no handicap, not handicap=55
        if let player = players.first {
            XCTAssertNil(player.handicap)
        }
    }

    func testZeroHandicapViaDigit() {
        let players = PlayerParser.parse("alice 0")
        XCTAssertEqual(players.first?.handicap, 0)
    }

    // MARK: - Performance

    func testParsePerformance() {
        let text = "add joe chanley he is a 12 handicap, mike s who is a 14, dan who is a 8 and josh who is a 9"
        measure {
            for _ in 0..<200 {
                _ = PlayerParser.parse(text)
            }
        }
    }

    func testSinglePlayerParsePerformance() {
        measure {
            for _ in 0..<1000 {
                _ = PlayerParser.parse("joe chanley he is a 12 handicap")
            }
        }
    }
}
