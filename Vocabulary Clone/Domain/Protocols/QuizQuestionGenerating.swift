/// Turns a set of real, ground-truth words into placement-test questions.
/// Abstracted behind a protocol — same reason as `VocabularyLevelAssessing`
/// — so the on-device Apple Intelligence implementation can be swapped for a
/// different model backend later without touching `QuizViewModel`, and can
/// fall back to a deterministic generator when no model is available.
protocol QuizQuestionGenerating {
    /// Returns exactly one question per candidate, in the same order given.
    func generateQuestions(from candidates: [QuizWordCandidate]) async throws -> [QuizQuestion]
}
