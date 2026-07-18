import Foundation

/// Decorates another `WordSeedProviding` (normally `JSONWordSeedSource`) by
/// reordering its output with `PersonalizedWordOrderer` before `DataSeedingService`
/// ever inserts a row — the personalized order becomes `sortIndex` at insert
/// time, so `ReelViewModel`/`SwiftDataWordRepository` need no changes at all.
struct PersonalizedWordSeedSource: WordSeedProviding {
    private let profile: OnboardingProfile
    private let signals: PersonalizationSignals
    private let placementWords: [PlacementWord]
    private let baseSource: WordSeedProviding
    private let tagsLoader: WordTagsLoader

    init(
        profile: OnboardingProfile,
        signals: PersonalizationSignals,
        placementWords: [PlacementWord],
        baseSource: WordSeedProviding = JSONWordSeedSource(),
        tagsLoader: WordTagsLoader = WordTagsLoader()
    ) {
        self.profile = profile
        self.signals = signals
        self.placementWords = placementWords
        self.baseSource = baseSource
        self.tagsLoader = tagsLoader
    }

    func loadEntries() throws -> [WordEntry] {
        let entries = try baseSource.loadEntries()
        guard let tags = try? tagsLoader.load() else {
            // Enrichment file missing/unreadable — seed in the original order
            // rather than failing app launch over a personalization nicety.
            return entries
        }
        return PersonalizedWordOrderer.order(
            entries,
            tags: tags,
            signals: signals,
            preferredTopics: OnboardingTopicMapper.tagKeys(for: profile),
            excludedWords: Set(placementWords.map(\.word))
        )
    }
}
