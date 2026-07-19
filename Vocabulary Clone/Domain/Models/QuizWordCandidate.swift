import Foundation

/// One real `oxford_5000` word offered to a `QuizQuestionGenerating`
/// implementation as ground truth. A generator may rephrase the question and
/// invent its own distractors, but the word, its definition, and its CEFR
/// band come straight from the source data — the same guarantee
/// `QuizQuestionBank`'s hand-picked questions make, just resampled fresh
/// each run instead of fixed.
struct QuizWordCandidate: Equatable {
    let word: String
    let definition: String
    let band: CEFRLevel
    /// Same 0 (a1) ... 1 (c1+) scale as `QuizQuestion.difficulty`.
    let difficulty: Double
}
