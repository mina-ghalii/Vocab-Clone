import XCTest
import SwiftData
@testable import Vocabulary_Clone

final class SwiftDataWordRepositoryTests: XCTestCase {
    private func makeContext() throws -> ModelContext {
        let schema = Schema([WordEntry.self, WordProgress.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }

    private func makeEntry(id: String, sortIndex: Int) -> WordEntry {
        WordEntry(id: id, word: id, ukAudioFile: "\(id)_uk.mp3", usAudioFile: "\(id)_us.mp3", sortIndex: sortIndex, senses: [])
    }

    // MARK: - WordQuerying

    func testWordAtSortIndexReturnsMatchingEntry() async throws {
        let context = try makeContext()
        context.insert(makeEntry(id: "a", sortIndex: 0))
        context.insert(makeEntry(id: "b", sortIndex: 1))
        let repository = SwiftDataWordRepository(modelContext: context)

        let result = try await repository.word(at: 1)

        XCTAssertEqual(result?.id, "b")
    }

    func testWordAtSortIndexReturnsNilWhenNoMatch() async throws {
        let context = try makeContext()
        let repository = SwiftDataWordRepository(modelContext: context)

        let result = try await repository.word(at: 0)

        XCTAssertNil(result)
    }

    func testWordsFromReturnsSortedEntriesStartingAtIndex() async throws {
        let context = try makeContext()
        context.insert(makeEntry(id: "c", sortIndex: 2))
        context.insert(makeEntry(id: "a", sortIndex: 0))
        context.insert(makeEntry(id: "b", sortIndex: 1))
        let repository = SwiftDataWordRepository(modelContext: context)

        let result = try await repository.words(from: 1, limit: 10)

        XCTAssertEqual(result.map(\.id), ["b", "c"])
    }

    func testWordsFromRespectsLimit() async throws {
        let context = try makeContext()
        for index in 0..<5 {
            context.insert(makeEntry(id: "e\(index)", sortIndex: index))
        }
        let repository = SwiftDataWordRepository(modelContext: context)

        let result = try await repository.words(from: 0, limit: 2)

        XCTAssertEqual(result.map(\.id), ["e0", "e1"])
    }

    func testTotalCountReflectsInsertedEntries() async throws {
        let context = try makeContext()
        context.insert(makeEntry(id: "a", sortIndex: 0))
        context.insert(makeEntry(id: "b", sortIndex: 1))
        let repository = SwiftDataWordRepository(modelContext: context)

        let count = try await repository.totalCount()

        XCTAssertEqual(count, 2)
    }

    // MARK: - WordStateMutating

    func testProgressCreatesNewRecordWhenNoneExists() async throws {
        let context = try makeContext()
        let repository = SwiftDataWordRepository(modelContext: context)

        let progress = try await repository.progress(for: "abandon")

        XCTAssertEqual(progress.entryId, "abandon")
        XCTAssertFalse(progress.isSeen)
    }

    func testProgressReturnsExistingRecordOnSecondCall() async throws {
        let context = try makeContext()
        let repository = SwiftDataWordRepository(modelContext: context)

        let first = try await repository.progress(for: "abandon")
        first.isLiked = true
        let second = try await repository.progress(for: "abandon")

        XCTAssertTrue(second.isLiked)
    }

    func testMarkSeenSetsSeenFlagAndTimestampOnce() async throws {
        let context = try makeContext()
        let repository = SwiftDataWordRepository(modelContext: context)

        try await repository.markSeen(entryId: "abandon")
        let progress = try await repository.progress(for: "abandon")
        XCTAssertTrue(progress.isSeen)
        XCTAssertNotNil(progress.seenAt)

        let firstSeenAt = progress.seenAt
        try await repository.markSeen(entryId: "abandon")
        XCTAssertEqual(progress.seenAt, firstSeenAt)
    }

    func testToggleLikedFlipsStateAndSetsTimestamp() async throws {
        let context = try makeContext()
        let repository = SwiftDataWordRepository(modelContext: context)

        let likedNow = try await repository.toggleLiked(entryId: "abandon")
        XCTAssertTrue(likedNow)
        let progressAfterLike = try await repository.progress(for: "abandon")
        XCTAssertNotNil(progressAfterLike.likedAt)

        let likedAfterToggle = try await repository.toggleLiked(entryId: "abandon")
        XCTAssertFalse(likedAfterToggle)
        XCTAssertNil(progressAfterLike.likedAt)
    }

    func testToggleSavedFlipsStateAndSetsTimestamp() async throws {
        let context = try makeContext()
        let repository = SwiftDataWordRepository(modelContext: context)

        let savedNow = try await repository.toggleSaved(entryId: "abandon")
        XCTAssertTrue(savedNow)
        let progressAfterSave = try await repository.progress(for: "abandon")
        XCTAssertNotNil(progressAfterSave.savedAt)

        let savedAfterToggle = try await repository.toggleSaved(entryId: "abandon")
        XCTAssertFalse(savedAfterToggle)
        XCTAssertNil(progressAfterSave.savedAt)
    }

    func testResumeIndexRoundTripsThroughUserDefaults() async throws {
        let context = try makeContext()
        let repository = SwiftDataWordRepository(modelContext: context)
        let originalValue = try await repository.resumeIndex()
        defer { UserDefaults.standard.set(originalValue, forKey: "reel.resumeIndex") }

        try await repository.setResumeIndex(42)

        let result = try await repository.resumeIndex()
        XCTAssertEqual(result, 42)
    }

    // MARK: - WordHistoryQuerying

    func testSeenEntriesReturnsMostRecentlySeenFirst() async throws {
        let context = try makeContext()
        context.insert(makeEntry(id: "a", sortIndex: 0))
        context.insert(makeEntry(id: "b", sortIndex: 1))
        let repository = SwiftDataWordRepository(modelContext: context)

        try await repository.markSeen(entryId: "a")
        let progressA = try await repository.progress(for: "a")
        progressA.seenAt = Date(timeIntervalSince1970: 1000)

        try await repository.markSeen(entryId: "b")
        let progressB = try await repository.progress(for: "b")
        progressB.seenAt = Date(timeIntervalSince1970: 2000)

        let result = try await repository.seenEntries()

        XCTAssertEqual(result.map(\.entry.id), ["b", "a"])
    }

    func testLikedEntriesOnlyIncludesLikedProgress() async throws {
        let context = try makeContext()
        context.insert(makeEntry(id: "a", sortIndex: 0))
        context.insert(makeEntry(id: "b", sortIndex: 1))
        let repository = SwiftDataWordRepository(modelContext: context)

        _ = try await repository.toggleLiked(entryId: "a")

        let result = try await repository.likedEntries()

        XCTAssertEqual(result.map(\.entry.id), ["a"])
    }

    func testSavedEntriesOnlyIncludesSavedProgress() async throws {
        let context = try makeContext()
        context.insert(makeEntry(id: "a", sortIndex: 0))
        context.insert(makeEntry(id: "b", sortIndex: 1))
        let repository = SwiftDataWordRepository(modelContext: context)

        _ = try await repository.toggleSaved(entryId: "b")

        let result = try await repository.savedEntries()

        XCTAssertEqual(result.map(\.entry.id), ["b"])
    }

    func testHistoryItemsSkipProgressRecordsWithNoMatchingEntry() async throws {
        let context = try makeContext()
        let repository = SwiftDataWordRepository(modelContext: context)

        // No WordEntry seeded for "orphan" — progress can still exist (e.g. stale data).
        try await repository.markSeen(entryId: "orphan")

        let result = try await repository.seenEntries()

        XCTAssertTrue(result.isEmpty)
    }
}
