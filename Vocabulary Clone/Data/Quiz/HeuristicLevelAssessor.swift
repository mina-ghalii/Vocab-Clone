import Foundation

/// Deterministic, model-free level assessment: the CEFR band is read off the
/// hardest question the learner still answered correctly, on the same 0
/// (a1) ... 1 (c1+) scale as `WordTags.difficulty`. Used as the on-device
/// model's fallback when Apple Intelligence isn't available on the device.
struct HeuristicLevelAssessor: VocabularyLevelAssessing {
    func assessLevel(from answers: [QuizAnswerRecord]) async throws -> QuizResult {
        let correctCount = answers.filter(\.isCorrect).count
        let highestCorrectDifficulty = answers.filter(\.isCorrect).map(\.question.difficulty).max() ?? 0
        let levelTitle = Self.levelTitle(forDifficulty: highestCorrectDifficulty)

        return QuizResult(
            correctCount: correctCount,
            totalCount: answers.count,
            levelTitle: levelTitle,
            summary: "You answered \(correctCount) of \(answers.count) words correctly, placing you around \(levelTitle). Keep practicing to climb higher."
        )
    }

    private static func levelTitle(forDifficulty difficulty: Double) -> String {
        switch difficulty {
        case ..<0.2: return "Beginner (A1)"
        case ..<0.4: return "Elementary (A2)"
        case ..<0.55: return "Intermediate (B1)"
        case ..<0.7: return "Upper Intermediate (B2)"
        default: return "Advanced (C1)"
        }
    }
}
