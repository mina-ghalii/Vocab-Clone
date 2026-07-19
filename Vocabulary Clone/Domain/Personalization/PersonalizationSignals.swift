import Foundation

/// The inferred reading level `PersonalizedWordOrderer` filters words against.
/// Produced either by `GeminiLevelInferenceGenerator` (cloud LLM, when
/// available) or `OnboardingProfileMapper` (deterministic, always available)
/// — the orderer doesn't know or care which one produced it. Topic preference
/// isn't part of this: it's read straight off `OnboardingProfile.topics` as a
/// plain filter, no inference needed.
struct PersonalizationSignals: Codable, Equatable {
    /// The CEFR band this user's words should start at. Only words at or above
    /// this level are shown.
    var targetLevel: CEFRLevel

    static let neutral = PersonalizationSignals(targetLevel: .a2)
}

extension PersonalizationSignals {
    private static let storageKey = "personalization.signals"

    /// Persists the resolved signals as JSON in `UserDefaults`, mirroring
    /// `OnboardingProfile.save`. This is the durable "current" reference a
    /// retest overwrites, not a debug-only convenience.
    func save(to defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(self) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }

    static func load(from defaults: UserDefaults = .standard) -> PersonalizationSignals? {
        guard let data = defaults.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(PersonalizationSignals.self, from: data)
    }
}
