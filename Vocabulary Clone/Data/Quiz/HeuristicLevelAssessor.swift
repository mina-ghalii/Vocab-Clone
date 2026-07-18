import Foundation

/// Deterministic, model-free level assessment: the CEFR band is read off the
/// hardest question the learner still answered correctly, on the same 0
/// (a1) ... 1 (c1+) scale as `QuizQuestion.difficulty`. Used as the on-device
/// model's fallback when Apple Intelligence isn't available on the device.
struct HeuristicLevelAssessor: VocabularyLevelAssessing {
    func assessLevel(from answers: [QuizAnswerRecord]) async throws -> QuizResult {
        let correctCount = answers.filter(\.isCorrect).count
        let highestCorrectDifficulty = answers.filter(\.isCorrect).map(\.question.difficulty).max() ?? 0
        let level = CEFRLevel.forDifficulty(highestCorrectDifficulty)
        let levelTitle = Self.levelTitle(for: level)

        return QuizResult(
            correctCount: correctCount,
            totalCount: answers.count,
            assessedLevel: level,
            levelTitle: levelTitle,
            summary: "You answered \(correctCount) of \(answers.count) words correctly, placing you around \(levelTitle). Keep practicing to climb higher."
        )
    }

    private static func levelTitle(for level: CEFRLevel) -> String {
        switch level {
        case .a1: return "Beginner (A1)"
        case .a2: return "Elementary (A2)"
        case .b1: return "Intermediate (B1)"
        case .b2: return "Upper Intermediate (B2)"
        case .c1: return "Advanced (C1)"
        }
    }
}
