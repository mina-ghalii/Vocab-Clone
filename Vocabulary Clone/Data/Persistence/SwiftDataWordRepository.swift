import Foundation
import SwiftData

/// SwiftData-backed implementation of the word read/write protocols. This is the
/// only place in the app that talks to `ModelContext` directly — swapping persistence
/// technology later means replacing this one file, nothing upstream.
final class SwiftDataWordRepository: WordQuerying, WordStateMutating {
    private static let resumeIndexKey = "reel.resumeIndex"

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - WordQuerying

    func word(at sortIndex: Int) async throws -> WordEntry? {
        var descriptor = FetchDescriptor<WordEntry>(
            predicate: #Predicate { $0.sortIndex == sortIndex }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    func words(from sortIndex: Int, limit: Int) async throws -> [WordEntry] {
        var descriptor = FetchDescriptor<WordEntry>(
            predicate: #Predicate { $0.sortIndex >= sortIndex },
            sortBy: [SortDescriptor(\.sortIndex)]
        )
        descriptor.fetchLimit = limit
        return try modelContext.fetch(descriptor)
    }

    func totalCount() async throws -> Int {
        try modelContext.fetchCount(FetchDescriptor<WordEntry>())
    }

    func resumeIndex() async throws -> Int {
        UserDefaults.standard.integer(forKey: Self.resumeIndexKey)
    }

    // MARK: - WordStateMutating

    func markSeen(entryId: String) async throws {
        let entryProgress = try await progress(for: entryId)
        guard !entryProgress.isSeen else { return }
        entryProgress.isSeen = true
        entryProgress.seenAt = Date()
        try modelContext.save()
    }

    func toggleLiked(entryId: String) async throws -> Bool {
        let entryProgress = try await progress(for: entryId)
        entryProgress.isLiked.toggle()
        entryProgress.likedAt = entryProgress.isLiked ? Date() : nil
        try modelContext.save()
        return entryProgress.isLiked
    }

    func toggleSaved(entryId: String) async throws -> Bool {
        let entryProgress = try await progress(for: entryId)
        entryProgress.isSaved.toggle()
        entryProgress.savedAt = entryProgress.isSaved ? Date() : nil
        try modelContext.save()
        return entryProgress.isSaved
    }

    func setResumeIndex(_ index: Int) async throws {
        UserDefaults.standard.set(index, forKey: Self.resumeIndexKey)
    }

    func progress(for entryId: String) async throws -> WordProgress {
        var descriptor = FetchDescriptor<WordProgress>(
            predicate: #Predicate { $0.entryId == entryId }
        )
        descriptor.fetchLimit = 1
        if let existing = try modelContext.fetch(descriptor).first {
            return existing
        }
        let created = WordProgress(entryId: entryId)
        modelContext.insert(created)
        return created
    }
}
