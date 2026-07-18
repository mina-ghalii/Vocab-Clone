import FoundationModels

/// Structured output shape for the on-device model: a single calibrated CEFR
/// level. `@Guide` both documents the field for the model and constrains it to
/// exactly `CEFRLevel`'s cases — no free-text parsing, no arbitrary decimal.
@Generable
struct GeneratedLevelAssessment {
    @Guide(description: "The user's demonstrated CEFR reading level", .anyOf(CEFRLevel.allCases.map(\.rawValue)))
    var level: String
}

/// Infers `PersonalizationSignals` using Apple's on-device Foundation Models
/// framework, grounded in exactly which real, CEFR-labeled words the user did
/// and didn't recognize. This is a *best-effort enhancement*, never a hard
/// dependency: `SystemLanguageModel` isn't guaranteed available (older/non-Pro
/// devices, Apple Intelligence disabled, region restrictions, model still
/// downloading), so every caller must catch and fall back to `OnboardingProfileMapper`.
struct LevelInferenceGenerator {
    enum GenerationError: Error {
        case modelUnavailable(SystemLanguageModel.Availability.UnavailableReason)
        case unrecognizedLevel(String)
    }

    func generateSignals(for profile: OnboardingProfile, placementWords: [PlacementWord]) async throws -> PersonalizationSignals {
        switch SystemLanguageModel.default.availability {
        case .available:
            break
        case .unavailable(let reason):
            throw GenerationError.modelUnavailable(reason)
        }

        let session = LanguageModelSession(instructions: Self.instructions)
        let response = try await session.respond(
            to: Self.prompt(for: profile, placementWords: placementWords),
            generating: GeneratedLevelAssessment.self
        )
        // `.anyOf` constrains generation to CEFRLevel's raw values, so this should
        // never actually miss — but the model's output is still external input.
        guard let level = CEFRLevel(rawValue: response.content.level) else {
            throw GenerationError.unrecognizedLevel(response.content.level)
        }
        return PersonalizationSignals(targetLevel: level)
    }

    private static let instructions = """
    You infer a vocabulary-learning app user's CEFR reading level from a short placement \
    checklist of real dictionary words spanning CEFR levels A1 to C1, plus their own \
    self-assessment. Weigh the checklist results more heavily than the self-assessment \
    — people often over- or under-estimate themselves, but which real words they \
    recognize is direct evidence.
    """

    private static func prompt(for profile: OnboardingProfile, placementWords: [PlacementWord]) -> String {
        var lines = ["Placement checklist results (word, CEFR band, recognized by user):"]
        for placementWord in placementWords {
            let knewIt = profile.knownPlacementWords.contains(placementWord.word)
            lines.append("- \(placementWord.word) (\(placementWord.band.rawValue.uppercased())): \(knewIt ? "recognized" : "not recognized")")
        }
        if let level = profile.vocabularyLevel {
            lines.append("Self-reported vocabulary level: \(level)")
        }
        if let frequency = profile.encounterFrequency {
            lines.append("Encounters unfamiliar words: \(frequency)")
        }
        if let description = profile.vocabularySelfDescription {
            lines.append("Self-description: \(description)")
        }
        return lines.joined(separator: "\n")
    }
}
