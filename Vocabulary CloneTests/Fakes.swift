import Foundation
import UIKit
@testable import Vocabulary_Clone

final class FakeWordRepository: WordQuerying, WordStateMutating, WordHistoryQuerying {
    var progressByEntryId: [String: WordProgress] = [:]

    func word(at sortIndex: Int) async throws -> WordEntry? { nil }
    func words(from sortIndex: Int, limit: Int) async throws -> [WordEntry] { [] }
    func totalCount() async throws -> Int { 0 }
    func resumeIndex() async throws -> Int { 0 }

    func markSeen(entryId: String) async throws {}
    func toggleLiked(entryId: String) async throws -> Bool { false }
    func toggleSaved(entryId: String) async throws -> Bool { false }
    func setResumeIndex(_ index: Int) async throws {}

    func progress(for entryId: String) async throws -> WordProgress {
        if let existing = progressByEntryId[entryId] { return existing }
        let progress = WordProgress(entryId: entryId)
        progressByEntryId[entryId] = progress
        return progress
    }

    func seenEntries() async throws -> [WordHistoryItem] { [] }
    func likedEntries() async throws -> [WordHistoryItem] { [] }
    func savedEntries() async throws -> [WordHistoryItem] { [] }
}

final class FakeAudioPlayer: AudioPlayerProtocol {
    private(set) var stopCallCount = 0

    func play(audioFileName: String) throws {}

    func stop() {
        stopCallCount += 1
    }
}

@MainActor
final class FakeShareImageGenerator: ShareImageGenerating {
    func image(for entry: WordEntry) -> UIImage? { nil }
}

final class FakeStreakTracking: StreakTracking {
    func recordAppOpened() -> Bool { false }
    func currentSummary() -> StreakSummary { StreakSummary(currentStreakCount: 0, days: []) }
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
