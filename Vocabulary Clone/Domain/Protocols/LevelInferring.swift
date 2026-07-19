/// Infers `PersonalizationSignals` from an onboarding profile and its
/// placement-checklist results. Abstracted behind a protocol — same reason
/// as `VocabularyLevelAssessing` and `QuizQuestionGenerating` — so the
/// on-device Apple Intelligence implementation can be swapped for a
/// different model backend later, and `PersonalizationSignalsResolver` can
/// fall back to the deterministic `OnboardingProfileMapper` when no model is
/// available.
protocol LevelInferring {
    func generateSignals(for profile: OnboardingProfile, placementWords: [PlacementWord]) async throws -> PersonalizationSignals
}
