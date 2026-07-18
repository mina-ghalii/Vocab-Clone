import XCTest
@testable import Vocabulary_Clone

@MainActor
final class WordListViewModelTests: XCTestCase {
    private func makeEntry(id: String) -> WordEntry {
        WordEntry(id: id, word: id, ukAudioFile: "\(id)_uk.mp3", usAudioFile: "\(id)_us.mp3", sortIndex: 0, senses: [])
    }

    private func makeItem(id: String) -> WordHistoryItem {
        WordHistoryItem(entry: makeEntry(id: id), progress: WordProgress(entryId: id), date: Date())
    }

    private func makeViewModel(
        kind: WordListKind,
        repository: FakeWordRepository,
        audioPlayer: FakeAudioPlayer? = nil,
        shareImageGenerator: FakeShareImageGenerator? = nil,
        preferredAccent: AudioAccent = .uk
    ) -> WordListViewModel {
        WordListViewModel(
            kind: kind,
            repository: repository,
            audioPlayer: audioPlayer ?? FakeAudioPlayer(),
            shareImageGenerator: shareImageGenerator ?? FakeShareImageGenerator(),
            preferredAccent: preferredAccent
        )
    }

    func testLoadPopulatesItemsForHistoryKind() async {
        let repository = FakeWordRepository()
        repository.seenEntriesToReturn = [makeItem(id: "abandon"), makeItem(id: "brave")]
        let viewModel = makeViewModel(kind: .history, repository: repository)

        await viewModel.load()

        XCTAssertEqual(viewModel.items.map(\.id), ["abandon", "brave"])
    }

    func testLoadPopulatesItemsForFavoritesKind() async {
        let repository = FakeWordRepository()
        repository.likedEntriesToReturn = [makeItem(id: "candid")]
        let viewModel = makeViewModel(kind: .favorites, repository: repository)

        await viewModel.load()

        XCTAssertEqual(viewModel.items.map(\.id), ["candid"])
    }

    func testLoadPopulatesItemsForSavedWordsKind() async {
        let repository = FakeWordRepository()
        repository.savedEntriesToReturn = [makeItem(id: "meticulous")]
        let viewModel = makeViewModel(kind: .savedWords, repository: repository)

        await viewModel.load()

        XCTAssertEqual(viewModel.items.map(\.id), ["meticulous"])
    }

    func testLoadFailureClearsItems() async {
        let repository = FakeWordRepository()
        repository.seenEntriesError = FakeRepositoryError.loadFailed
        let viewModel = makeViewModel(kind: .history, repository: repository)

        await viewModel.load()

        XCTAssertTrue(viewModel.items.isEmpty)
    }

    func testToggleLikeCallsRepositoryAndReloads() async {
        let repository = FakeWordRepository()
        let item = makeItem(id: "abandon")
        repository.likedEntriesToReturn = [item]
        let viewModel = makeViewModel(kind: .favorites, repository: repository)
        await viewModel.load()

        repository.likedEntriesToReturn = []
        await viewModel.toggleLike(item)

        XCTAssertEqual(repository.toggleLikedEntryIds, ["abandon"])
        XCTAssertTrue(viewModel.items.isEmpty)
    }

    func testToggleSaveCallsRepositoryAndReloads() async {
        let repository = FakeWordRepository()
        let item = makeItem(id: "brave")
        repository.savedEntriesToReturn = [item]
        let viewModel = makeViewModel(kind: .savedWords, repository: repository)
        await viewModel.load()

        repository.savedEntriesToReturn = []
        await viewModel.toggleSave(item)

        XCTAssertEqual(repository.toggleSavedEntryIds, ["brave"])
        XCTAssertTrue(viewModel.items.isEmpty)
    }

    func testPlayAudioStopsThenPlaysTheAccentSpecificFile() {
        let repository = FakeWordRepository()
        let audioPlayer = FakeAudioPlayer()
        let viewModel = makeViewModel(kind: .history, repository: repository, audioPlayer: audioPlayer, preferredAccent: .us)

        viewModel.playAudio(makeEntry(id: "abandon"))

        XCTAssertEqual(audioPlayer.stopCallCount, 1)
        XCTAssertEqual(audioPlayer.lastPlayedFileName, "abandon_us.mp3")
    }

    func testPlayAudioUsesUKFileForUKAccent() {
        let repository = FakeWordRepository()
        let audioPlayer = FakeAudioPlayer()
        let viewModel = makeViewModel(kind: .history, repository: repository, audioPlayer: audioPlayer, preferredAccent: .uk)

        viewModel.playAudio(makeEntry(id: "abandon"))

        XCTAssertEqual(audioPlayer.lastPlayedFileName, "abandon_uk.mp3")
    }

    func testShareTappedSetsPendingShareWhenImageGeneratorSucceeds() {
        let repository = FakeWordRepository()
        let shareGenerator = FakeShareImageGenerator()
        shareGenerator.imageToReturn = UIImage()
        let viewModel = makeViewModel(kind: .history, repository: repository, shareImageGenerator: shareGenerator)

        viewModel.shareTapped(makeEntry(id: "abandon"))

        XCTAssertNotNil(viewModel.pendingShare)
    }

    func testShareTappedDoesNothingWhenImageGeneratorReturnsNil() {
        let repository = FakeWordRepository()
        let viewModel = makeViewModel(kind: .history, repository: repository)

        viewModel.shareTapped(makeEntry(id: "abandon"))

        XCTAssertNil(viewModel.pendingShare)
    }
}
