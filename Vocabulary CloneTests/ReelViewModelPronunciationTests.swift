import XCTest
@testable import Vocabulary_Clone

@MainActor
final class ReelViewModelPronunciationTests: XCTestCase {
    private func makeViewModel(speechRecognizer: SpeechRecognizing) -> ReelViewModel {
        ReelViewModel(
            repository: FakeWordRepository(),
            audioPlayer: FakeAudioPlayer(),
            shareImageGenerator: FakeShareImageGenerator(),
            streakTracking: FakeStreakTracking(),
            speechRecognizer: speechRecognizer
        )
    }

    private func makeEntry(word: String = "abandon") -> WordEntry {
        WordEntry(
            id: word,
            word: word,
            ukAudioFile: "\(word)_uk.mp3",
            usAudioFile: "\(word)_us.mp3",
            sortIndex: 0,
            senses: []
        )
    }

    func testBeginPronunciationCheckStartsRecordingWhenAuthorized() async {
        let speech = FakeSpeechRecognizer()
        let viewModel = makeViewModel(speechRecognizer: speech)
        let entry = makeEntry()

        await viewModel.beginPronunciationCheck(for: entry)

        XCTAssertEqual(viewModel.pronunciationState, .recording)
        XCTAssertEqual(speech.startRecordingCallCount, 1)
    }

    func testBeginPronunciationCheckFailsClosedWhenUnauthorized() async {
        let speech = FakeSpeechRecognizer()
        speech.isAuthorized = false
        let viewModel = makeViewModel(speechRecognizer: speech)
        let entry = makeEntry()

        await viewModel.beginPronunciationCheck(for: entry)

        XCTAssertEqual(viewModel.pronunciationState, .incorrect(transcript: ""))
        XCTAssertEqual(speech.startRecordingCallCount, 0)
    }

    func testBeginPronunciationCheckMarksIncorrectWhenStartRecordingThrows() async {
        let speech = FakeSpeechRecognizer()
        speech.startRecordingError = FakeSpeechRecognizerError.cannotStart
        let viewModel = makeViewModel(speechRecognizer: speech)
        let entry = makeEntry()

        await viewModel.beginPronunciationCheck(for: entry)

        XCTAssertEqual(viewModel.pronunciationState, .incorrect(transcript: ""))
    }

    func testEndPronunciationCheckMarksCorrectOnMatchingTranscript() async {
        let speech = FakeSpeechRecognizer()
        speech.transcriptToReturn = "abandon"
        let viewModel = makeViewModel(speechRecognizer: speech)
        let entry = makeEntry(word: "abandon")

        await viewModel.beginPronunciationCheck(for: entry)
        await viewModel.endPronunciationCheck(for: entry)

        XCTAssertEqual(viewModel.pronunciationState, .correct)
        XCTAssertEqual(speech.stopRecordingCallCount, 1)
    }

    func testEndPronunciationCheckMarksIncorrectOnMismatchedTranscript() async {
        let speech = FakeSpeechRecognizer()
        speech.transcriptToReturn = "banana"
        let viewModel = makeViewModel(speechRecognizer: speech)
        let entry = makeEntry(word: "abandon")

        await viewModel.beginPronunciationCheck(for: entry)
        await viewModel.endPronunciationCheck(for: entry)

        XCTAssertEqual(viewModel.pronunciationState, .incorrect(transcript: "banana"))
    }

    func testEndPronunciationCheckIsNoOpWhenNotRecording() async {
        let speech = FakeSpeechRecognizer()
        let viewModel = makeViewModel(speechRecognizer: speech)
        let entry = makeEntry()

        await viewModel.endPronunciationCheck(for: entry)

        XCTAssertEqual(viewModel.pronunciationState, .idle)
        XCTAssertEqual(speech.stopRecordingCallCount, 0)
    }

    func testCardAppearedResetsPronunciationState() async {
        let speech = FakeSpeechRecognizer()
        speech.transcriptToReturn = "abandon"
        let viewModel = makeViewModel(speechRecognizer: speech)
        let entry = makeEntry(word: "abandon")

        await viewModel.beginPronunciationCheck(for: entry)
        await viewModel.endPronunciationCheck(for: entry)
        XCTAssertEqual(viewModel.pronunciationState, .correct)

        await viewModel.cardAppeared(entry, at: 0)

        XCTAssertEqual(viewModel.pronunciationState, .idle)
    }
}
