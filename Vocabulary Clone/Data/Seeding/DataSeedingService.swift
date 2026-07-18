import Foundation
import SwiftData

/// Populates the SwiftData store from `WordSeedProviding` exactly once. On every
/// launch after the first, `seedIfNeeded()` finds existing rows and returns immediately
/// without touching the seed source again.
final class DataSeedingService: WordSeeding {
    private let modelContext: ModelContext
    private let seedProvider: WordSeedProviding
    private let chunkSize: Int

    nonisolated deinit {}

    init(modelContext: ModelContext, seedProvider: WordSeedProviding, chunkSize: Int = 500) {
        self.modelContext = modelContext
        self.seedProvider = seedProvider
        self.chunkSize = chunkSize
    }

    func seedIfNeeded() async throws {
        let existingCount = try modelContext.fetchCount(FetchDescriptor<WordEntry>())
        guard existingCount == 0 else { return }

        let entries = try seedProvider.loadEntries()
        for chunk in entries.chunked(into: chunkSize) {
            for entry in chunk {
                modelContext.insert(entry)
            }
            try modelContext.save()
        }
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
