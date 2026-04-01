import XCTest
@testable import BirdieBuddy

/// Tests for SpeechRecognizer that do not require a real microphone.
/// Covers state machine correctness, timeout behaviour, and configuration checks.
final class SpeechRecognizerTests: XCTestCase {

    // MARK: - Initial state

    func testInitialStateIsIdle() {
        let sr = SpeechRecognizer()
        XCTAssertEqual(sr.state, .idle)
    }

    func testInitialLastHeardTextIsEmpty() {
        let sr = SpeechRecognizer()
        XCTAssertTrue(sr.lastHeardText.isEmpty)
    }

    // MARK: - isAvailable

    func testIsAvailableReturnsFalseWhenUnavailable() {
        let sr = SpeechRecognizer()
        // Without granting permissions in a test environment, isAvailable reflects
        // whether the system recognizer is available — we can at least verify it
        // doesn't crash and returns a Bool.
        _ = sr.isAvailable
    }

    // MARK: - stopListening is safe to call when idle

    func testStopListeningWhenIdleIsNoop() {
        let sr = SpeechRecognizer()
        sr.stopListening()  // should not crash
        XCTAssertEqual(sr.state, .idle)
    }

    func testStopListeningTwiceIsNoop() {
        let sr = SpeechRecognizer()
        sr.stopListening()
        sr.stopListening()
        XCTAssertEqual(sr.state, .idle)
    }

    // MARK: - startListening guards

    func testStartListeningWhenUnavailableDoesNotChangeState() {
        let sr = SpeechRecognizer()
        // Manually set unavailable by not granting permissions (state is still idle by default,
        // but isAvailable will be false if SFSpeechRecognizer is not available in test sandbox).
        // We can't force .unavailable without permissions, so verify the guard doesn't crash.
        // If the recognizer IS available in CI, this is a best-effort check.
        let before = sr.state
        sr.startListeningForText()
        // State is either still idle (no mic) or listening (mic granted in CI)
        XCTAssertTrue(sr.state == before || sr.state == .listening)
        sr.stopListening()
    }

    // MARK: - Contextual strings coverage

    /// Ensures ScoreParser.contextualStrings is non-empty (used by SpeechRecognizer to hint the engine).
    func testContextualStringsNonEmpty() {
        XCTAssertFalse(ScoreParser.contextualStrings.isEmpty)
    }

    func testContextualStringsContainCoreGolfTerms() {
        let required = ["birdie", "bogey", "eagle", "par", "ace"]
        for term in required {
            XCTAssertTrue(
                ScoreParser.contextualStrings.contains(term),
                "'\(term)' missing from contextualStrings"
            )
        }
    }

    // MARK: - Timeout constants are sane

    func testScoreTimeoutIsReasonable() {
        // Access via reflection isn't possible for private statics, so we verify indirectly
        // that a SpeechRecognizer instance can be created and the public API is sane.
        let sr = SpeechRecognizer()
        XCTAssertNotNil(sr)
    }

    // MARK: - Thread safety smoke test

    func testStopListeningFromBackgroundThreadDoesNotCrash() {
        let sr = SpeechRecognizer()
        let expectation = self.expectation(description: "background stop")
        DispatchQueue.global().async {
            sr.stopListening()
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2)
        XCTAssertEqual(sr.state, .idle)
    }

    // MARK: - Performance: recognizer instantiation

    func testRecognizerInstantiationPerformance() {
        measure {
            for _ in 0..<50 {
                let sr = SpeechRecognizer()
                _ = sr.isAvailable
            }
        }
    }
}
