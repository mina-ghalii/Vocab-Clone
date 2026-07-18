import Foundation

/// Turns a completed placement-test run into a `QuizResult`. Abstracted behind
/// a protocol so the on-device Apple Intelligence implementation can fall back
/// to a deterministic heuristic when the model isn't available on the device.
protocol VocabularyLevelAssessing {
    func assessLevel(from answers: [QuizAnswerRecord]) async throws -> QuizResult
}
