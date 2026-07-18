import Foundation

/// Every answer collected across the onboarding flow, captured so it can drive
/// word personalization afterward. All fields are optional/empty-defaulted since
/// every onboarding question is skippable.
struct OnboardingProfile: Codable, Equatable {
    var referralSource: String?
    var ageRange: String?
    var gender: String?
    var name: String?
    var topics: Set<String> = []
    var curiosityMotivations: Set<String> = []
    var vocabularyLevel: String?
    var encounterFrequency: String?
    var vocabularySelfDescription: String?
    var weakestAreas: Set<String> = []
    /// Words the user checked off across all three placement checklist screens.
    /// The screens themselves are populated from real `oxford_5000` words (see
    /// `PlacementWordsLoader`), each carrying its own real CEFR band, so scoring
    /// never needs to guess a tier's difficulty — it looks each word up directly.
    var knownPlacementWords: Set<String> = []
}

extension OnboardingProfile {
    private static let storageKey = "onboarding.profile"

    /// Persists the profile as JSON in `UserDefaults`, alongside the other
    /// onboarding outputs (`readingTheme`, `preferredAccent`) already stored there.
    func save(to defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(self) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }

    static func load(from defaults: UserDefaults = .standard) -> OnboardingProfile? {
        guard let data = defaults.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(OnboardingProfile.self, from: data)
    }
}
