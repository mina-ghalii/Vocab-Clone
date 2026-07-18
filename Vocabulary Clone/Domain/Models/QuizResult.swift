import Foundation

/// The outcome of a full placement-test run, shown on the final screen.
struct QuizResult: Equatable {
    let correctCount: Int
    let totalCount: Int
    /// Deterministic CEFR band derived from the answer pattern, independent of
    /// whichever assessor produced `levelTitle` — this is what personalization
    /// acts on when re-seeding after a retest.
    let assessedLevel: CEFRLevel
    /// e.g. "Advanced (C1)" — either written by the on-device model or, if it's
    /// unavailable, derived from the heuristic fallback.
    let levelTitle: String
    /// A couple of sentences of feedback tailored to the answer pattern.
    let summary: String
}
