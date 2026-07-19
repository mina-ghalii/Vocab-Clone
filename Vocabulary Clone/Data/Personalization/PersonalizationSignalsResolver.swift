import Foundation

/// Single entry point for turning an `OnboardingProfile` into `PersonalizationSignals`:
/// tries the Gemini-backed generator first, falls back to the deterministic
/// rule-based mapper on any failure (no connectivity, bad key, generation
/// error, decoding error — all collapse to the same safe fallback). Lives in
/// the Data layer, not Domain, since it orchestrates a concrete
/// I/O-performing generator.
enum PersonalizationSignalsResolver {
    static func resolve(for profile: OnboardingProfile, placementWords: [PlacementWord]) async -> PersonalizationSignals {
        await resolve(for: profile, placementWords: placementWords, aiGenerator: GeminiLevelInferenceGenerator())
    }

    static func resolve(
        for profile: OnboardingProfile,
        placementWords: [PlacementWord],
        aiGenerator: LevelInferring
    ) async -> PersonalizationSignals {
        do {
            let generated = try await aiGenerator.generateSignals(for: profile, placementWords: placementWords)
            generated.save()
            return generated
        } catch {
            #if DEBUG
            print("[PersonalizationSignalsResolver] falling back to OnboardingProfileMapper — \(error)")
            #endif
        }
        let mapped = OnboardingProfileMapper.map(profile, placementWords: placementWords)
        mapped.save()
        return mapped
    }
}
