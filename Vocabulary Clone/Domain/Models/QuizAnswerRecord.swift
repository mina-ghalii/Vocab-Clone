import Foundation

/// One answered question, kept for the whole run so the level assessor can see
/// the full pattern of rights/wrongs across difficulty, not just a final tally.
struct QuizAnswerRecord: Equatable {
    let question: QuizQuestion
    let selectedOptionIndex: Int
    let isCorrect: Bool
}
