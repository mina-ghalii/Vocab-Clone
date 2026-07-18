import Foundation

/// The inferred reading level `PersonalizedWordOrderer` filters words against.
/// Produced either by `LevelInferenceGenerator` (on-device LLM, when available)
/// or `OnboardingProfileMapper` (deterministic, always available) — the orderer
/// doesn't know or care which one produced it. Topic preference isn't part of
/// this: it's read straight off `OnboardingProfile.topics` as a plain filter,
/// no inference needed.
struct PersonalizationSignals: Codable, Equatable {
    /// The CEFR band this user's words should start at. Only words at or above
    /// this level are shown.
    var targetLevel: CEFRLevel

    static let neutral = PersonalizationSignals(targetLevel: .a2)
}

#if DEBUG
extension PersonalizationSignals {
    private static let storageKey = "debug.personalizationSignals"

    /// Debug-only: stashes the resolved signals (and which source produced them)
    /// so the reel can display what onboarding actually inferred. Remove alongside
    /// the debug badge in `WordCardView`.
    func saveForDebugging(source: String, to defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(self) else { return }
        defaults.set(data, forKey: Self.storageKey)
        defaults.set(source, forKey: Self.storageKey + ".source")
    }

    static func loadForDebugging(from defaults: UserDefaults = .standard) -> (signals: PersonalizationSignals, source: String)? {
        guard let data = defaults.data(forKey: storageKey),
              let signals = try? JSONDecoder().decode(PersonalizationSignals.self, from: data) else { return nil }
        return (signals, defaults.string(forKey: storageKey + ".source") ?? "unknown")
    }
}
#endif
