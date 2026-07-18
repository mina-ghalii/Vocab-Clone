import Foundation

/// Deterministic, rule-based level inference — the mandatory fallback used
/// whenever the on-device model (`LevelInferenceGenerator`) is unavailable or
/// fails. Takes `placementWords` as a parameter rather than loading them itself,
/// so this stays pure/testable like the rest of Domain.
enum OnboardingProfileMapper {
    private static let vocabularyLevelBaseline: [String: Double] = [
        "Beginner": 0.0,
        "Intermediate": 0.4,
        "Advanced": 0.8,
    ]

    static func map(_ profile: OnboardingProfile, placementWords: [PlacementWord]) -> PersonalizationSignals {
        let selfReportedBaseline = profile.vocabularyLevel.flatMap { vocabularyLevelBaseline[$0] }
        guard let checklistEstimate = checklistDifficultyEstimate(profile, placementWords: placementWords) else {
            return PersonalizationSignals(targetDifficulty: selfReportedBaseline ?? 0.2)
        }
        guard let selfReportedBaseline else {
            return PersonalizationSignals(targetDifficulty: checklistEstimate)
        }

        // Checklist is the stronger evidence (graded against real words);
        // self-report only nudges it.
        let blended = checklistEstimate * 0.75 + selfReportedBaseline * 0.25
        return PersonalizationSignals(targetDifficulty: min(1, max(0, blended)))
    }

    /// Walks CEFR bands from hardest to easiest and returns the difficulty of the
    /// hardest band where the user still recognized at least half the words shown
    /// — the highest level they've actually demonstrated, not just claimed.
    private static func checklistDifficultyEstimate(_ profile: OnboardingProfile, placementWords: [PlacementWord]) -> Double? {
        guard !placementWords.isEmpty else { return nil }

        let wordsByDifficulty = Dictionary(grouping: placementWords, by: \.difficulty)
        let bandsHardestFirst = wordsByDifficulty.keys.sorted(by: >)

        for difficulty in bandsHardestFirst {
            guard let wordsInBand = wordsByDifficulty[difficulty], !wordsInBand.isEmpty else { continue }
            let knownCount = wordsInBand.filter { profile.knownPlacementWords.contains($0.word) }.count
            let knownFraction = Double(knownCount) / Double(wordsInBand.count)
            if knownFraction >= 0.5 {
                return difficulty
            }
        }
        // Didn't clear even the easiest band shown — that band's difficulty is
        // still a more informed floor than falling through to a hardcoded default.
        return bandsHardestFirst.last
    }
}
