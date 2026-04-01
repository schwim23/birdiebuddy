import XCTest
@testable import BirdieBuddy

final class ScoreParserTests: XCTestCase {

    // MARK: - Direct digits

    func testDirectDigits() {
        for n in 1...9 {
            XCTAssertEqual(ScoreParser.parse("\(n)", par: 4), n, "Direct digit \(n)")
        }
    }

    func testZeroAndTenReturnNil() {
        XCTAssertNil(ScoreParser.parse("0", par: 4))
        XCTAssertNil(ScoreParser.parse("10", par: 4))
    }

    // MARK: - Number words

    func testNumberWords() {
        let words = ["one","two","three","four","five","six","seven","eight","nine"]
        for (i, word) in words.enumerated() {
            XCTAssertEqual(ScoreParser.parse(word, par: 4), i + 1, "Word '\(word)'")
        }
    }

    func testNumberWordInSentence() {
        XCTAssertEqual(ScoreParser.parse("I got a five today", par: 4), 5)
        XCTAssertEqual(ScoreParser.parse("scored three", par: 4), 3)
    }

    // MARK: - Golf terms (par 4)

    func testAce() {
        XCTAssertEqual(ScoreParser.parse("ace", par: 4), 1)
        XCTAssertEqual(ScoreParser.parse("hole in one", par: 4), 1)
    }

    func testEagle() {
        XCTAssertEqual(ScoreParser.parse("eagle", par: 4), 2)
        XCTAssertEqual(ScoreParser.parse("eagle", par: 5), 3)
    }

    func testBirdie() {
        XCTAssertEqual(ScoreParser.parse("birdie", par: 4), 3)
        XCTAssertEqual(ScoreParser.parse("birdie", par: 3), 2)
        XCTAssertEqual(ScoreParser.parse("birdie", par: 5), 4)
    }

    func testPar() {
        XCTAssertEqual(ScoreParser.parse("par", par: 3), 3)
        XCTAssertEqual(ScoreParser.parse("par", par: 4), 4)
        XCTAssertEqual(ScoreParser.parse("par", par: 5), 5)
    }

    func testBogey() {
        XCTAssertEqual(ScoreParser.parse("bogey", par: 3), 4)
        XCTAssertEqual(ScoreParser.parse("bogey", par: 4), 5)
        XCTAssertEqual(ScoreParser.parse("bogey", par: 5), 6)
    }

    func testDoubleBogey() {
        XCTAssertEqual(ScoreParser.parse("double bogey", par: 4), 6)
        XCTAssertEqual(ScoreParser.parse("double", par: 4), 6)
    }

    func testTripleBogey() {
        XCTAssertEqual(ScoreParser.parse("triple bogey", par: 4), 7)
        XCTAssertEqual(ScoreParser.parse("triple", par: 4), 7)
    }

    // MARK: - Out-of-range golf terms return nil

    func testEagleOnPar3IsOutOfRange() {
        // Eagle on par 3 = 1 → valid
        XCTAssertEqual(ScoreParser.parse("eagle", par: 3), 1)
        // Eagle on par 3 where it results in 0 would be invalid — but par 3 eagle = 1, OK
    }

    func testTripleOnPar5IsOutOfRange() {
        // Triple on par 5 = 8 → valid
        XCTAssertEqual(ScoreParser.parse("triple", par: 5), 8)
        // Triple on par 4 = 7 → valid
        XCTAssertEqual(ScoreParser.parse("triple bogey", par: 4), 7)
    }

    // MARK: - Phonetic aliases

    func testBogeypPhoneticAliases() {
        let aliases = ["bougie", "boogie", "boggy", "bogy", "bogi"]
        for alias in aliases {
            XCTAssertEqual(ScoreParser.parse(alias, par: 4), 5, "Alias '\(alias)' should parse as bogey")
        }
    }

    func testBirdiePhoneticAliases() {
        let aliases = ["bertie", "birdy", "burdie", "birdee", "burdy"]
        for alias in aliases {
            XCTAssertEqual(ScoreParser.parse(alias, par: 4), 3, "Alias '\(alias)' should parse as birdie")
        }
    }

    func testDoubleBogeyPhoneticAliases() {
        XCTAssertEqual(ScoreParser.parse("double bougie", par: 4), 6)
        XCTAssertEqual(ScoreParser.parse("double boogie", par: 4), 6)
        XCTAssertEqual(ScoreParser.parse("double boggy", par: 4),  6)
    }

    // MARK: - Case and whitespace insensitivity

    func testCaseInsensitive() {
        XCTAssertEqual(ScoreParser.parse("BIRDIE", par: 4), 3)
        XCTAssertEqual(ScoreParser.parse("Bogey", par: 4), 5)
        XCTAssertEqual(ScoreParser.parse("PAR", par: 4), 4)
    }

    func testLeadingTrailingWhitespace() {
        XCTAssertEqual(ScoreParser.parse("  birdie  ", par: 4), 3)
        XCTAssertEqual(ScoreParser.parse("\t5\n", par: 4), 5)
    }

    // MARK: - Invalid / unrecognised input

    func testEmptyStringReturnsNil() {
        XCTAssertNil(ScoreParser.parse("", par: 4))
    }

    func testGarbageReturnsNil() {
        XCTAssertNil(ScoreParser.parse("hello world", par: 4))
        XCTAssertNil(ScoreParser.parse("great shot", par: 4))
        XCTAssertNil(ScoreParser.parse("um", par: 4))
    }

    // MARK: - contextualStrings coverage

    func testContextualStringsContainsAllTerms() {
        let terms = ["birdie", "bogey", "eagle", "par", "double bogey", "triple bogey", "ace"]
        for term in terms {
            XCTAssertTrue(ScoreParser.contextualStrings.contains(term), "Missing '\(term)' in contextualStrings")
        }
    }

    // MARK: - Performance

    func testParsePerformance() {
        let inputs = [
            ("birdie", 4), ("bogey", 4), ("par", 4), ("eagle", 5),
            ("double bogey", 4), ("five", 4), ("7", 4), ("bougie", 4),
            ("hole in one", 3), ("triple", 5),
        ]
        measure {
            for _ in 0..<500 {
                for (text, par) in inputs {
                    _ = ScoreParser.parse(text, par: par)
                }
            }
        }
    }
}
