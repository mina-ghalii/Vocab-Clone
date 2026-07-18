import Foundation

/// The inferred reading level `PersonalizedWordOrderer` filters words against.
/// Produced either by `LevelInferenceGenerator` (on-device LLM, when available)
/// or `OnboardingProfileMapper` (deterministic, always available) — the orderer
/// doesn't know or care which one produced it. Topic preference isn't part of
/// this: it's read straight off `OnboardingProfile.topics` as a plain filter,
/// no inference needed.
struct PersonalizationSignals: Codable, Equatable {
    /// Where on the 0 (a1) ... 1 (c1) CEFR scale this user's words should start.
    /// Only words at or above this are shown.
    var targetDifficulty: Double

    static let neutral = PersonalizationSignals(targetDifficulty: 0.2)
}
