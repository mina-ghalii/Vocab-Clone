import Foundation

/// Infers `PersonalizationSignals` using the Gemini API, grounded in exactly
/// which real, CEFR-labeled words the user did and didn't recognize.
/// Replaces the on-device Apple Intelligence path. This is a *best-effort
/// enhancement*, never a hard dependency: the network call can fail (no
/// connectivity, bad key, rate limit), so every caller must catch and fall
/// back to `OnboardingProfileMapper`.
struct GeminiLevelInferenceGenerator: LevelInferring {
    enum GenerationError: Error {
        case unrecognizedLevel(String)
    }

    private let client: GeminiClient

    init(apiKey: String = Secrets.geminiAPIKey) {
        client = GeminiClient(apiKey: apiKey)
    }

    func generateSignals(for profile: OnboardingProfile, placementWords: [PlacementWord]) async throws -> PersonalizationSignals {
        let response: GeneratedLevelAssessment = try await client.generate(
            systemInstruction: Self.instructions,
            prompt: Self.prompt(for: profile, placementWords: placementWords),
            responseSchema: Self.responseSchema,
            as: GeneratedLevelAssessment.self
        )
        guard let level = CEFRLevel(rawValue: response.level) else {
            throw GenerationError.unrecognizedLevel(response.level)
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

    private static let responseSchema = GeminiSchema(
        type: "OBJECT",
        properties: ["level": GeminiSchema(type: "STRING", enumValues: CEFRLevel.allCases.map(\.rawValue))],
        required: ["level"]
    )
}

private struct GeneratedLevelAssessment: Decodable {
    let level: String
}
