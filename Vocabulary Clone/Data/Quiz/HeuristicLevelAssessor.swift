import Foundation

/// Deterministic, model-free level assessment: the CEFR band is read off
/// `CEFRLevel.assessed(from:)`, the same band-by-band pattern read every
/// other assessor uses. Used as the on-device model's fallback when Apple
/// Intelligence isn't available on the device.
struct HeuristicLevelAssessor: VocabularyLevelAssessing {
    func assessLevel(from answers: [QuizAnswerRecord]) async throws -> QuizResult {
        let correctCount = answers.filter(\.isCorrect).count
        let level = CEFRLevel.assessed(from: answers)
        let levelTitle = level.displayTitle

        return QuizResult(
            correctCount: correctCount,
            totalCount: answers.count,
            assessedLevel: level,
            levelTitle: levelTitle,
            summary: "You answered \(correctCount) of \(answers.count) words correctly, placing you around \(levelTitle). Keep practicing to climb higher."
        )
    }
}
