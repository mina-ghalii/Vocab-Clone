import Foundation

/// Deterministic, rule-based level inference — the mandatory fallback used
/// whenever the on-device model (`LevelInferenceGenerator`) is unavailable or
/// fails. Takes `placementWords` as a parameter rather than loading them itself,
/// so this stays pure/testable like the rest of Domain.
enum OnboardingProfileMapper {
    private static let vocabularyLevelBaseline: [String: CEFRLevel] = [
        "Beginner": .a1,
        "Intermediate": .b1,
        "Advanced": .c1,
    ]

    static func map(_ profile: OnboardingProfile, placementWords: [PlacementWord]) -> PersonalizationSignals {
        let selfReportedBaseline = profile.vocabularyLevel.flatMap { vocabularyLevelBaseline[$0] }
        guard let checklistEstimate = checklistLevelEstimate(profile, placementWords: placementWords) else {
            return PersonalizationSignals(targetLevel: selfReportedBaseline ?? .a2)
        }
        guard let selfReportedBaseline else {
            return PersonalizationSignals(targetLevel: checklistEstimate)
        }

        return PersonalizationSignals(targetLevel: nudge(checklistEstimate, towards: selfReportedBaseline))
    }

    /// Walks CEFR bands from hardest to easiest and returns the band of the
    /// hardest one where the user still recognized at least half the words shown
    /// — the highest level they've actually demonstrated, not just claimed.
    private static func checklistLevelEstimate(_ profile: OnboardingProfile, placementWords: [PlacementWord]) -> CEFRLevel? {
        guard !placementWords.isEmpty else { return nil }

        let wordsByBand = Dictionary(grouping: placementWords, by: \.band)
        let bandsHardestFirst = wordsByBand.keys.sorted(by: >)

        for band in bandsHardestFirst {
            guard let wordsInBand = wordsByBand[band], !wordsInBand.isEmpty else { continue }
            let knownCount = wordsInBand.filter { profile.knownPlacementWords.contains($0.word) }.count
            let knownFraction = Double(knownCount) / Double(wordsInBand.count)
            if knownFraction >= 0.5 {
                return band
            }
        }
        // Didn't clear even the easiest band shown — that band is still a more
        // informed floor than falling through to a hardcoded default.
        return bandsHardestFirst.last
    }

    /// Checklist is the stronger evidence (graded against real words), so it's
    /// the result unless self-report disagrees by more than one band — then it's
    /// nudged a single band that way, just enough to correct a checklist that
    /// undersold itself without letting self-perception override direct evidence.
    private static func nudge(_ checklist: CEFRLevel, towards selfReported: CEFRLevel) -> CEFRLevel {
        let cases = CEFRLevel.allCases
        let checklistIndex = cases.firstIndex(of: checklist)!
        let selfReportedIndex = cases.firstIndex(of: selfReported)!

        switch selfReportedIndex - checklistIndex {
        case 2...: return cases[min(checklistIndex + 1, cases.count - 1)]
        case ...(-2): return cases[max(checklistIndex - 1, 0)]
        default: return checklist
        }
    }
}
