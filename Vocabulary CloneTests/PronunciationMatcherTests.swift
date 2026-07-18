import XCTest
@testable import Vocabulary_Clone

final class PronunciationMatcherTests: XCTestCase {
    func testExactMatchIsCorrect() {
        XCTAssertTrue(PronunciationMatcher.isMatch(transcript: "abandon", target: "abandon"))
    }

    func testCaseAndPunctuationAreIgnored() {
        XCTAssertTrue(PronunciationMatcher.isMatch(transcript: "Abandon.", target: "abandon"))
    }

    func testWordEmbeddedInFillerPhraseStillMatches() {
        XCTAssertTrue(PronunciationMatcher.isMatch(transcript: "um abandon", target: "abandon"))
    }

    func testMinorTranscriptionSlipIsTolerated() {
        // one-letter edit on a word longer than 3 letters
        XCTAssertTrue(PronunciationMatcher.isMatch(transcript: "abandom", target: "abandon"))
    }

    func testUnrelatedWordDoesNotMatch() {
        XCTAssertFalse(PronunciationMatcher.isMatch(transcript: "banana", target: "abandon"))
    }

    func testShortWordsRequireExactMatch() {
        XCTAssertFalse(PronunciationMatcher.isMatch(transcript: "in", target: "at"))
        XCTAssertTrue(PronunciationMatcher.isMatch(transcript: "at", target: "at"))
    }

    func testEmptyTranscriptDoesNotMatch() {
        XCTAssertFalse(PronunciationMatcher.isMatch(transcript: "", target: "abandon"))
    }
}
