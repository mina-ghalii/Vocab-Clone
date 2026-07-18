import Foundation

/// Single entry point for turning an `OnboardingProfile` into `PersonalizationSignals`:
/// tries the on-device Foundation Models generator first, falls back to the
/// deterministic rule-based mapper on any failure (unavailable model, generation
/// error, decoding error — all collapse to the same safe fallback). Lives in the
/// Data layer, not Domain, since it orchestrates a concrete I/O-performing generator.
enum PersonalizationSignalsResolver {
    static func resolve(for profile: OnboardingProfile, placementWords: [PlacementWord]) async -> PersonalizationSignals {
        await resolve(for: profile, placementWords: placementWords, aiGenerator: LevelInferenceGenerator())
    }

    static func resolve(
        for profile: OnboardingProfile,
        placementWords: [PlacementWord],
        aiGenerator: LevelInferenceGenerator
    ) async -> PersonalizationSignals {
        if let generated = try? await aiGenerator.generateSignals(for: profile, placementWords: placementWords) {
            #if DEBUG
            generated.saveForDebugging(source: "Apple AI")
            #endif
            return generated
        }
        let mapped = OnboardingProfileMapper.map(profile, placementWords: placementWords)
        #if DEBUG
        mapped.saveForDebugging(source: "rule-based fallback")
        #endif
        return mapped
    }
}
