import XCTest
@testable import BirdieBuddy

final class MultiScoreParserTests: XCTestCase {

    // Helpers
    private func players(_ names: String...) -> [Player] {
        names.map { Player(name: $0, handicap: 0) }
    }

    // MARK: - Single player

    func testSinglePlayerDigit() {
        let result = MultiScoreParser.parse("joe 5", players: players("Joe"), par: 4)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].playerName, "Joe")
        XCTAssertEqual(result[0].strokes, 5)
    }

    func testSinglePlayerGolfTerm() {
        let result = MultiScoreParser.parse("joe got a bogey", players: players("Joe"), par: 4)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].playerName, "Joe")
        XCTAssertEqual(result[0].strokes, 5)
    }

    func testSinglePlayerBirdie() {
        let result = MultiScoreParser.parse("mike birdied that hole", players: players("Mike"), par: 4)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].strokes, 3)
    }

    func testSinglePlayerDouble() {
        let result = MultiScoreParser.parse("sam doubled", players: players("Sam"), par: 4)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].strokes, 6)
    }

    func testSinglePlayerPar() {
        let result = MultiScoreParser.parse("dan made par", players: players("Dan"), par: 5)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].strokes, 5)
    }

    // MARK: - Multiple players, comma-separated

    func testFourPlayersCommaSeparated() {
        let ps = players("Joe", "Mike", "Dan", "Josh")
        let result = MultiScoreParser.parse("joe 5, mike bogey, dan par, josh birdie", players: ps, par: 4)
        XCTAssertEqual(result.count, 4)
        XCTAssertEqual(result.first { $0.playerName == "Joe"  }?.strokes, 5)
        XCTAssertEqual(result.first { $0.playerName == "Mike" }?.strokes, 5)
        XCTAssertEqual(result.first { $0.playerName == "Dan"  }?.strokes, 4)
        XCTAssertEqual(result.first { $0.playerName == "Josh" }?.strokes, 3)
    }

    func testFullVoicePhrase() {
        let ps = players("Joe", "Mike", "Sam", "Jon")
        let input = "joe got a bogey, mike got a par, sam doubled and jon birdied that hole"
        let result = MultiScoreParser.parse(input, players: ps, par: 4)
        XCTAssertEqual(result.count, 4)
        XCTAssertEqual(result.first { $0.playerName == "Joe"  }?.strokes, 5)
        XCTAssertEqual(result.first { $0.playerName == "Mike" }?.strokes, 4)
        XCTAssertEqual(result.first { $0.playerName == "Sam"  }?.strokes, 6)
        XCTAssertEqual(result.first { $0.playerName == "Jon"  }?.strokes, 3)
    }

    // MARK: - Connector splitting

    func testAndConnector() {
        let ps = players("Joe", "Mike")
        let result = MultiScoreParser.parse("joe par and mike bogey", players: ps, par: 4)
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result.first { $0.playerName == "Joe"  }?.strokes, 4)
        XCTAssertEqual(result.first { $0.playerName == "Mike" }?.strokes, 5)
    }

    func testThenConnector() {
        let ps = players("Alice", "Bob")
        let result = MultiScoreParser.parse("alice birdie then bob 6", players: ps, par: 4)
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result.first { $0.playerName == "Alice" }?.strokes, 3)
        XCTAssertEqual(result.first { $0.playerName == "Bob"   }?.strokes, 6)
    }

    // MARK: - "everyone" / "all" special phrases

    func testEveryonePar() {
        let ps = players("Joe", "Mike", "Dan", "Josh")
        let result = MultiScoreParser.parse("everyone made par", players: ps, par: 4)
        XCTAssertEqual(result.count, 4)
        XCTAssertTrue(result.allSatisfy { $0.strokes == 4 })
    }

    func testEveryoneBogey() {
        let ps = players("Joe", "Mike")
        let result = MultiScoreParser.parse("everyone bogey", players: ps, par: 5)
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.allSatisfy { $0.strokes == 6 })
    }

    func testAllPar() {
        let ps = players("Alice", "Bob", "Carol")
        let result = MultiScoreParser.parse("all par", players: ps, par: 3)
        XCTAssertEqual(result.count, 3)
        XCTAssertTrue(result.allSatisfy { $0.strokes == 3 })
    }

    func testEveryoneGotBirdie() {
        let ps = players("Joe", "Mike")
        let result = MultiScoreParser.parse("everyone got a birdie", players: ps, par: 4)
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.allSatisfy { $0.strokes == 3 })
    }

    // MARK: - Partial match

    func testPartialMatchTwoOfFour() {
        let ps = players("Joe", "Mike", "Dan", "Josh")
        let result = MultiScoreParser.parse("joe birdie, mike bogey", players: ps, par: 4)
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result.first { $0.playerName == "Joe"  }?.strokes, 3)
        XCTAssertEqual(result.first { $0.playerName == "Mike" }?.strokes, 5)
    }

    // MARK: - Unrecognised player name ignored

    func testUnknownPlayerIgnored() {
        let ps = players("Joe", "Mike")
        let result = MultiScoreParser.parse("joe par, sarah bogey", players: ps, par: 4)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].playerName, "Joe")
    }

    func testAllUnknownPlayersReturnsEmpty() {
        let ps = players("Joe", "Mike")
        let result = MultiScoreParser.parse("alice par, bob bogey", players: ps, par: 4)
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - Duplicate player — first match wins

    func testDuplicatePlayerNameDeduped() {
        let ps = players("Joe", "Mike")
        let result = MultiScoreParser.parse("joe par, joe bogey", players: ps, par: 4)
        XCTAssertEqual(result.filter { $0.playerName == "Joe" }.count, 1)
        XCTAssertEqual(result.first { $0.playerName == "Joe" }?.strokes, 4)
    }

    // MARK: - Case insensitivity

    func testCaseInsensitivePlayerName() {
        let result = MultiScoreParser.parse("JOE par", players: players("Joe"), par: 4)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].playerName, "Joe")
        XCTAssertEqual(result[0].strokes, 4)
    }

    func testCaseInsensitiveGolfTerm() {
        let result = MultiScoreParser.parse("joe BIRDIE", players: players("Joe"), par: 4)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].strokes, 3)
    }

    // MARK: - Whitespace handling

    func testLeadingTrailingWhitespace() {
        let result = MultiScoreParser.parse("  joe par  ", players: players("Joe"), par: 4)
        XCTAssertEqual(result.count, 1)
    }

    func testExtraSpacesBetweenTokens() {
        let result = MultiScoreParser.parse("joe   par", players: players("Joe"), par: 4)
        XCTAssertEqual(result.count, 1)
    }

    // MARK: - Empty / edge cases

    func testEmptyTextReturnsEmpty() {
        XCTAssertTrue(MultiScoreParser.parse("", players: players("Joe"), par: 4).isEmpty)
    }

    func testNoPlayersReturnsEmpty() {
        XCTAssertTrue(MultiScoreParser.parse("joe par", players: [], par: 4).isEmpty)
    }

    func testUnparsableScoreIgnored() {
        let ps = players("Joe", "Mike")
        let result = MultiScoreParser.parse("joe hello, mike par", players: ps, par: 4)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].playerName, "Mike")
    }

    // MARK: - Two-word player name

    func testTwoWordPlayerName() {
        let result = MultiScoreParser.parse("joe chan par", players: players("Joe Chan"), par: 4)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].playerName, "Joe Chan")
        XCTAssertEqual(result[0].strokes, 4)
    }

    func testTwoWordNameFallsBackToFirstName() {
        // "Joe" alone still matches "Joe Chan"
        let result = MultiScoreParser.parse("joe par", players: players("Joe Chan"), par: 4)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].playerName, "Joe Chan")
    }

    // MARK: - Mixed golf terms and digits

    func testMixedTermsAndDigits() {
        let ps = players("Joe", "Mike", "Dan")
        let result = MultiScoreParser.parse("joe birdie, mike 5, dan triple", players: ps, par: 4)
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result.first { $0.playerName == "Joe"  }?.strokes, 3)
        XCTAssertEqual(result.first { $0.playerName == "Mike" }?.strokes, 5)
        XCTAssertEqual(result.first { $0.playerName == "Dan"  }?.strokes, 7)
    }

    // MARK: - Performance

    func testParsePerformance() {
        let ps = players("Joe", "Mike", "Dan", "Josh")
        let input = "joe got a bogey, mike got a par, dan doubled and josh birdied that hole"
        measure {
            for _ in 0..<500 {
                _ = MultiScoreParser.parse(input, players: ps, par: 4)
            }
        }
    }
}
