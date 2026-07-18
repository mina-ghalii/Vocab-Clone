import XCTest
@testable import Vocabulary_Clone

@MainActor
final class ReelViewModelTests: XCTestCase {
    private func makeEntry(id: String, sortIndex: Int) -> WordEntry {
        WordEntry(id: id, word: id, ukAudioFile: "\(id)_uk.mp3", usAudioFile: "\(id)_us.mp3", sortIndex: sortIndex, senses: [])
    }

    private func makeViewModel(
        repository: FakeWordRepository,
        audioPlayer: FakeAudioPlayer? = nil,
        shareImageGenerator: FakeShareImageGenerator? = nil,
        streakTracking: FakeStreakTracking? = nil,
        pageSize: Int = 20,
        prefetchThreshold: Int = 5
    ) -> ReelViewModel {
        ReelViewModel(
            repository: repository,
            audioPlayer: audioPlayer ?? FakeAudioPlayer(),
            shareImageGenerator: shareImageGenerator ?? FakeShareImageGenerator(),
            streakTracking: streakTracking ?? FakeStreakTracking(),
            speechRecognizer: FakeSpeechRecognizer(),
            pageSize: pageSize,
            prefetchThreshold: prefetchThreshold
        )
    }

    func testStartLoadsWindowedEntriesAroundResumeIndex() async {
        let repository = FakeWordRepository()
        repository.totalCountToReturn = 50
        repository.resumeIndexToReturn = 10
        repository.wordsByFromIndex[10] = [makeEntry(id: "a", sortIndex: 10), makeEntry(id: "b", sortIndex: 11)]
        let viewModel = makeViewModel(repository: repository)

        await viewModel.start()

        XCTAssertEqual(viewModel.loadedEntries.map(\.id), ["a", "b"])
        XCTAssertEqual(viewModel.totalCount, 50)
    }

    func testStartIsNoOpWhenEntriesAlreadyLoaded() async {
        let repository = FakeWordRepository()
        repository.totalCountToReturn = 10
        repository.wordsByFromIndex[0] = [makeEntry(id: "a", sortIndex: 0)]
        let viewModel = makeViewModel(repository: repository)

        await viewModel.start()
        await viewModel.start()

        XCTAssertEqual(repository.totalCountCallCount, 1)
    }

    func testStartClearsEntriesWhenLoadingFails() async {
        let repository = FakeWordRepository()
        repository.totalCountToReturn = 10
        repository.wordsError = FakeRepositoryError.loadFailed
        let viewModel = makeViewModel(repository: repository)

        await viewModel.start()

        XCTAssertTrue(viewModel.loadedEntries.isEmpty)
    }

    func testCardAppearedMarksSeenAndUpdatesResumeIndex() async {
        let repository = FakeWordRepository()
        repository.totalCountToReturn = 10
        repository.wordsByFromIndex[0] = [makeEntry(id: "a", sortIndex: 0)]
        let viewModel = makeViewModel(repository: repository, pageSize: 1, prefetchThreshold: 5)
        await viewModel.start()

        await viewModel.cardAppeared(viewModel.loadedEntries[0], at: 0)

        XCTAssertEqual(repository.markSeenEntryIds, ["a"])
        XCTAssertEqual(repository.setResumeIndexCalls, [0])
    }

    func testCardAppearedLoadsMoreEntriesWhenNearingEndOfWindow() async {
        let repository = FakeWordRepository()
        repository.totalCountToReturn = 6
        repository.wordsByFromIndex[0] = [
            makeEntry(id: "e0", sortIndex: 0),
            makeEntry(id: "e1", sortIndex: 1),
            makeEntry(id: "e2", sortIndex: 2),
            makeEntry(id: "e3", sortIndex: 3),
        ]
        repository.wordsByFromIndex[4] = [makeEntry(id: "e4", sortIndex: 4), makeEntry(id: "e5", sortIndex: 5)]
        let viewModel = makeViewModel(repository: repository, pageSize: 4, prefetchThreshold: 1)
        await viewModel.start()

        // localIndex 3 is within `prefetchThreshold` of the loaded window's end (4 entries).
        await viewModel.cardAppeared(viewModel.loadedEntries[3], at: 3)

        XCTAssertEqual(viewModel.loadedEntries.map(\.id), ["e0", "e1", "e2", "e3", "e4", "e5"])
    }

    func testCardAppearedDoesNotLoadMoreWhenFarFromEndOfWindow() async {
        let repository = FakeWordRepository()
        repository.totalCountToReturn = 6
        repository.wordsByFromIndex[0] = [
            makeEntry(id: "e0", sortIndex: 0),
            makeEntry(id: "e1", sortIndex: 1),
            makeEntry(id: "e2", sortIndex: 2),
            makeEntry(id: "e3", sortIndex: 3),
        ]
        let viewModel = makeViewModel(repository: repository, pageSize: 4, prefetchThreshold: 1)
        await viewModel.start()

        await viewModel.cardAppeared(viewModel.loadedEntries[0], at: 0)

        XCTAssertEqual(viewModel.loadedEntries.count, 4)
    }

    func testCardAppearedDoesNotLoadMoreWhenAlreadyAtLastPage() async {
        let repository = FakeWordRepository()
        repository.totalCountToReturn = 4
        repository.wordsByFromIndex[0] = [
            makeEntry(id: "e0", sortIndex: 0),
            makeEntry(id: "e1", sortIndex: 1),
            makeEntry(id: "e2", sortIndex: 2),
            makeEntry(id: "e3", sortIndex: 3),
        ]
        let viewModel = makeViewModel(repository: repository, pageSize: 4, prefetchThreshold: 2)
        await viewModel.start()

        await viewModel.cardAppeared(viewModel.loadedEntries[3], at: 3)

        XCTAssertEqual(viewModel.loadedEntries.count, 4)
    }

    func testToggleLikeCallsRepositoryAndRefreshesProgress() async {
        let repository = FakeWordRepository()
        let viewModel = makeViewModel(repository: repository)
        let entry = makeEntry(id: "abandon", sortIndex: 0)

        await viewModel.toggleLike(entry)

        XCTAssertEqual(repository.toggleLikedEntryIds, ["abandon"])
        XCTAssertNotNil(viewModel.progressByEntryId["abandon"])
    }

    func testToggleSaveCallsRepositoryAndRefreshesProgress() async {
        let repository = FakeWordRepository()
        let viewModel = makeViewModel(repository: repository)
        let entry = makeEntry(id: "brave", sortIndex: 0)

        await viewModel.toggleSave(entry)

        XCTAssertEqual(repository.toggleSavedEntryIds, ["brave"])
        XCTAssertNotNil(viewModel.progressByEntryId["brave"])
    }

    func testPlayCurrentAudioPlaysTheSelectedAccentFile() {
        let repository = FakeWordRepository()
        let audioPlayer = FakeAudioPlayer()
        let viewModel = ReelViewModel(
            repository: repository,
            audioPlayer: audioPlayer,
            shareImageGenerator: FakeShareImageGenerator(),
            streakTracking: FakeStreakTracking(),
            speechRecognizer: FakeSpeechRecognizer(),
            preferredAccent: .us
        )

        viewModel.playCurrentAudio(for: makeEntry(id: "abandon", sortIndex: 0))

        XCTAssertEqual(audioPlayer.lastPlayedFileName, "abandon_us.mp3")
    }

    func testShareCurrentCardSetsPendingShareWhenGeneratorSucceeds() {
        let repository = FakeWordRepository()
        let shareGenerator = FakeShareImageGenerator()
        shareGenerator.imageToReturn = UIImage()
        let viewModel = makeViewModel(repository: repository, shareImageGenerator: shareGenerator)

        viewModel.shareCurrentCard(makeEntry(id: "abandon", sortIndex: 0))

        XCTAssertNotNil(viewModel.pendingShare)
    }

    func testShareCurrentCardDoesNothingWhenGeneratorReturnsNil() {
        let repository = FakeWordRepository()
        let viewModel = makeViewModel(repository: repository)

        viewModel.shareCurrentCard(makeEntry(id: "abandon", sortIndex: 0))

        XCTAssertNil(viewModel.pendingShare)
    }

    func testPresentStreakPanelHidesPanelWhenNotFirstOpenToday() async {
        let repository = FakeWordRepository()
        let streak = FakeStreakTracking()
        streak.recordAppOpenedResult = false
        streak.summaryToReturn = StreakSummary(currentStreakCount: 3, days: [])
        let viewModel = makeViewModel(repository: repository, streakTracking: streak)

        await viewModel.presentStreakPanelIfNeeded()

        XCTAssertEqual(viewModel.streakSummary?.currentStreakCount, 3)
        XCTAssertFalse(viewModel.isStreakPanelVisible)
    }

    func testPresentStreakPanelShowsPanelImmediatelyOnFirstOpenToday() async throws {
        let repository = FakeWordRepository()
        let streak = FakeStreakTracking()
        streak.recordAppOpenedResult = true
        streak.summaryToReturn = StreakSummary(currentStreakCount: 1, days: [])
        let viewModel = makeViewModel(repository: repository, streakTracking: streak)

        Task { await viewModel.presentStreakPanelIfNeeded() }
        try await Task.sleep(for: .milliseconds(50))

        XCTAssertTrue(viewModel.isStreakPanelVisible)
        XCTAssertEqual(viewModel.streakSummary?.currentStreakCount, 1)
    }
}
