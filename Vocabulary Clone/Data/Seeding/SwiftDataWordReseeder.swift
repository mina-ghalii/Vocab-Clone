import Foundation
import SwiftData

/// Re-orders every already-seeded `WordEntry` row against freshly resolved
/// `PersonalizationSignals` — the retest counterpart to `PersonalizedWordSeedSource`,
/// which only ever runs once against an empty store. Reuses the same
/// `PersonalizedWordOrderer.order` used at initial seed, just fetching existing
/// rows instead of decoding the bundled JSON.
struct SwiftDataWordReseeder: WordReseeding {
    private let modelContext: ModelContext
    private let profile: OnboardingProfile
    private let tagsLoader: WordTagsLoader
    private let excludedWords: Set<String>

    init(
        modelContext: ModelContext,
        profile: OnboardingProfile,
        tagsLoader: WordTagsLoader = WordTagsLoader(),
        placementWords: [PlacementWord] = (try? PlacementWordsLoader().load()) ?? []
    ) {
        self.modelContext = modelContext
        self.profile = profile
        self.tagsLoader = tagsLoader
        self.excludedWords = Set(placementWords.map(\.word))
            .union(QuizQuestionBank.questions.map(\.word))
    }

    func reseed(signals: PersonalizationSignals) async throws {
        signals.save()

        let entries = try modelContext.fetch(FetchDescriptor<WordEntry>())
        let tags = (try? tagsLoader.load()) ?? [:]

        _ = PersonalizedWordOrderer.order(
            entries,
            tags: tags,
            signals: signals,
            preferredTopics: OnboardingTopicMapper.tagKeys(for: profile),
            excludedWords: excludedWords
        )

        try modelContext.save()

        // sortIndex was just reassigned across the whole store, so the reel's
        // saved scroll position (a raw sortIndex) would otherwise resume at an
        // arbitrary point in the new order — reset it to the front.
        try await SwiftDataWordRepository(modelContext: modelContext).setResumeIndex(0)
    }
}
