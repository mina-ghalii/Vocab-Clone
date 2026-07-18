import Foundation
import UIKit
@testable import Vocabulary_Clone

final class FakeWordRepository: WordQuerying, WordStateMutating, WordHistoryQuerying {
    var progressByEntryId: [String: WordProgress] = [:]

    var seenEntriesToReturn: [WordHistoryItem] = []
    var likedEntriesToReturn: [WordHistoryItem] = []
    var savedEntriesToReturn: [WordHistoryItem] = []
    var seenEntriesError: Error?
    var likedEntriesError: Error?
    var savedEntriesError: Error?

    var toggleLikedResult = false
    var toggleSavedResult = false
    private(set) var toggleLikedEntryIds: [String] = []
    private(set) var toggleSavedEntryIds: [String] = []

    var totalCountToReturn = 0
    var resumeIndexToReturn = 0
    var wordsByFromIndex: [Int: [WordEntry]] = [:]
    var wordsError: Error?
    private(set) var totalCountCallCount = 0
    private(set) var markSeenEntryIds: [String] = []
    private(set) var setResumeIndexCalls: [Int] = []

    func word(at sortIndex: Int) async throws -> WordEntry? { nil }

    func words(from sortIndex: Int, limit: Int) async throws -> [WordEntry] {
        if let wordsError { throw wordsError }
        return wordsByFromIndex[sortIndex] ?? []
    }

    func totalCount() async throws -> Int {
        totalCountCallCount += 1
        return totalCountToReturn
    }

    func resumeIndex() async throws -> Int { resumeIndexToReturn }

    func markSeen(entryId: String) async throws {
        markSeenEntryIds.append(entryId)
    }

    func toggleLiked(entryId: String) async throws -> Bool {
        toggleLikedEntryIds.append(entryId)
        return toggleLikedResult
    }

    func toggleSaved(entryId: String) async throws -> Bool {
        toggleSavedEntryIds.append(entryId)
        return toggleSavedResult
    }

    func setResumeIndex(_ index: Int) async throws {
        setResumeIndexCalls.append(index)
    }

    func progress(for entryId: String) async throws -> WordProgress {
        if let existing = progressByEntryId[entryId] { return existing }
        let progress = WordProgress(entryId: entryId)
        progressByEntryId[entryId] = progress
        return progress
    }

    func seenEntries() async throws -> [WordHistoryItem] {
        if let seenEntriesError { throw seenEntriesError }
        return seenEntriesToReturn
    }

    func likedEntries() async throws -> [WordHistoryItem] {
        if let likedEntriesError { throw likedEntriesError }
        return likedEntriesToReturn
    }

    func savedEntries() async throws -> [WordHistoryItem] {
        if let savedEntriesError { throw savedEntriesError }
        return savedEntriesToReturn
    }
}

enum FakeRepositoryError: Error, Equatable {
    case loadFailed
}

final class FakeWordSeedProvider: WordSeedProviding {
    var entriesToReturn: [WordEntry] = []
    var errorToThrow: Error?
    private(set) var loadEntriesCallCount = 0

    func loadEntries() throws -> [WordEntry] {
        loadEntriesCallCount += 1
        if let errorToThrow { throw errorToThrow }
        return entriesToReturn
    }
}

final class FakeAudioPlayer: AudioPlayerProtocol {
    private(set) var stopCallCount = 0
    private(set) var lastPlayedFileName: String?
    var playError: Error?

    func play(audioFileName: String) throws {
        if let playError { throw playError }
        lastPlayedFileName = audioFileName
    }

    func stop() {
        stopCallCount += 1
    }
}

@MainActor
final class FakeShareImageGenerator: ShareImageGenerating {
    var imageToReturn: UIImage?

    func image(for entry: WordEntry) -> UIImage? { imageToReturn }
}

final class FakeStreakTracking: StreakTracking {
    var recordAppOpenedResult = false
    var summaryToReturn = StreakSummary(currentStreakCount: 0, days: [])

    func recordAppOpened() -> Bool { recordAppOpenedResult }
    func currentSummary() -> StreakSummary { summaryToReturn }
}

/// Scripted `SpeechRecognizing` fake: lets tests dictate authorization,
/// start-recording failures, and the transcript returned on stop.
final class FakeSpeechRecognizer: SpeechRecognizing {
    var isAuthorized = true
    var startRecordingError: Error?
    var transcriptToReturn = ""

    private(set) var didRequestAuthorization = false
    private(set) var startRecordingCallCount = 0
    private(set) var stopRecordingCallCount = 0

    func requestAuthorization() async -> Bool {
        didRequestAuthorization = true
        return isAuthorized
    }

    func startRecording() throws {
        startRecordingCallCount += 1
        if let startRecordingError { throw startRecordingError }
    }

    func stopRecording() async throws -> String {
        stopRecordingCallCount += 1
        return transcriptToReturn
    }
}

enum FakeSpeechRecognizerError: Error {
    case cannotStart
}

/// Scripted `VocabularyLevelAssessing` fake: lets tests dictate the result
/// returned (or error thrown) for a placement-test run.
final class FakeLevelAssessor: VocabularyLevelAssessing {
    var resultToReturn = QuizResult(correctCount: 0, totalCount: 0, levelTitle: "Beginner (A1)", summary: "")
    var errorToThrow: Error?

    private(set) var assessLevelCallCount = 0
    private(set) var lastAnswers: [QuizAnswerRecord] = []

    func assessLevel(from answers: [QuizAnswerRecord]) async throws -> QuizResult {
        assessLevelCallCount += 1
        lastAnswers = answers
        if let errorToThrow { throw errorToThrow }
        return resultToReturn
    }
}
