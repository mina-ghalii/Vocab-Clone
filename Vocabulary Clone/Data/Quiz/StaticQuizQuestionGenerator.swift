/// Always returns the fixed, hand-picked bank, ignoring the candidate pool.
/// Used as `GeminiQuizQuestionGenerator`'s fallback when the network call
/// fails, and directly wherever a deterministic quiz is wanted (previews,
/// tests).
struct StaticQuizQuestionGenerator: QuizQuestionGenerating {
    func generateQuestions(from candidates: [QuizWordCandidate]) async throws -> [QuizQuestion] {
        QuizQuestionBank.questions
    }
}
