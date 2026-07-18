import XCTest
import SwiftData
@testable import Vocabulary_Clone

final class DataSeedingServiceTests: XCTestCase {
    private func makeContext() throws -> ModelContext {
        let schema = Schema([WordEntry.self, WordProgress.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }

    private func makeEntry(id: String, sortIndex: Int) -> WordEntry {
        WordEntry(id: id, word: id, ukAudioFile: "\(id)_uk.mp3", usAudioFile: "\(id)_us.mp3", sortIndex: sortIndex, senses: [])
    }

    func testSeedIfNeededInsertsAllProvidedEntriesWhenStoreIsEmpty() async throws {
        let context = try makeContext()
        let provider = FakeWordSeedProvider()
        provider.entriesToReturn = (0..<5).map { makeEntry(id: "e\($0)", sortIndex: $0) }
        let service = DataSeedingService(modelContext: context, seedProvider: provider)

        try await service.seedIfNeeded()

        let count = try context.fetchCount(FetchDescriptor<WordEntry>())
        XCTAssertEqual(count, 5)
    }

    func testSeedIfNeededSplitsInsertsAcrossChunks() async throws {
        let context = try makeContext()
        let provider = FakeWordSeedProvider()
        provider.entriesToReturn = (0..<10).map { makeEntry(id: "e\($0)", sortIndex: $0) }
        let service = DataSeedingService(modelContext: context, seedProvider: provider, chunkSize: 3)

        try await service.seedIfNeeded()

        let count = try context.fetchCount(FetchDescriptor<WordEntry>())
        XCTAssertEqual(count, 10)
    }

    func testSeedIfNeededDoesNothingWhenStoreAlreadyHasEntries() async throws {
        let context = try makeContext()
        context.insert(makeEntry(id: "existing", sortIndex: 0))
        let provider = FakeWordSeedProvider()
        provider.entriesToReturn = [makeEntry(id: "new", sortIndex: 1)]
        let service = DataSeedingService(modelContext: context, seedProvider: provider)

        try await service.seedIfNeeded()

        XCTAssertEqual(provider.loadEntriesCallCount, 0)
        let count = try context.fetchCount(FetchDescriptor<WordEntry>())
        XCTAssertEqual(count, 1)
    }

    func testSeedIfNeededPropagatesProviderError() async throws {
        let context = try makeContext()
        let provider = FakeWordSeedProvider()
        provider.errorToThrow = FakeRepositoryError.loadFailed
        let service = DataSeedingService(modelContext: context, seedProvider: provider)

        do {
            try await service.seedIfNeeded()
            XCTFail("Expected seedIfNeeded to throw")
        } catch {
            XCTAssertEqual(error as? FakeRepositoryError, .loadFailed)
        }

        let count = try context.fetchCount(FetchDescriptor<WordEntry>())
        XCTAssertEqual(count, 0)
    }
}
