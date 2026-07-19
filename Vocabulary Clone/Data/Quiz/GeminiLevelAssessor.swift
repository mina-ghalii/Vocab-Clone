import Foundation

/// Determines the CEFR band deterministically (`CEFRLevel.assessed(from:)`,
/// same as `HeuristicLevelAssessor`), then sends the placement-test
/// transcript to the Gemini API for short, specific feedback about that
/// result — richer than a plain percentage score, but never the source of
/// the level itself. Replaces the on-device Apple Intelligence path. Falls
/// back to `HeuristicLevelAssessor` entirely when the network call fails or
/// its output fails validation.
struct GeminiLevelAssessor: VocabularyLevelAssessing {
    private let client: GeminiClient
    private let fallback: VocabularyLevelAssessing = HeuristicLevelAssessor()

    init(apiKey: String = Secrets.geminiAPIKey) {
        client = GeminiClient(apiKey: apiKey)
    }

    func assessLevel(from answers: [QuizAnswerRecord]) async throws -> QuizResult {
        let correctCount = answers.filter(\.isCorrect).count
        // The CEFR band itself is decided deterministically — see
        // `CEFRLevel.assessed(from:)` — never by the model, so it can't drift
        // from what `PersonalizationSignals` actually persists. The model's
        // job is limited to writing feedback text about that fixed result.
        let assessedLevel = CEFRLevel.assessed(from: answers)
        let levelTitle = assessedLevel.displayTitle

        do {
            let transcript = answers
                .map { "\($0.question.word) (difficulty \(String(format: "%.2f", $0.question.difficulty))): \($0.isCorrect ? "correct" : "incorrect")" }
                .joined(separator: "\n")

            let assessment: GeneratedFeedback = try await client.generate(
                systemInstruction: Self.instructions,
                prompt: "Placement test results (assessed level: \(levelTitle)):\n\(transcript)",
                responseSchema: Self.responseSchema,
                as: GeneratedFeedback.self
            )

            return QuizResult(
                correctCount: correctCount,
                totalCount: answers.count,
                assessedLevel: assessedLevel,
                levelTitle: levelTitle,
                summary: assessment.summary
            )
        } catch {
            #if DEBUG
            print("[LevelAssessor] Gemini feedback generation failed, falling back to heuristic — \(error)")
            #endif
            return try await fallback.assessLevel(from: answers)
        }
    }

    private static let instructions = """
        You are a vocabulary assessor writing feedback for an English \
        placement test. You'll be given each quiz word, its difficulty from \
        0.0 (beginner) to 1.0 (advanced), whether the learner answered \
        correctly, and the CEFR level already determined for them. Write \
        short, encouraging, specific feedback about their vocabulary level \
        and where to focus next — don't restate the level itself, the \
        reader already sees it separately.
        """

    private static let responseSchema = GeminiSchema(
        type: "OBJECT",
        properties: ["summary": GeminiSchema(type: "STRING")],
        required: ["summary"]
    )
}

private struct GeneratedFeedback: Decodable {
    let summary: String
}
