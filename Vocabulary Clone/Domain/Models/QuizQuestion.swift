import Foundation

/// The three placement-test question formats, matching the reel's own card-based
/// interaction style so the test doesn't feel like a different app.
enum QuizQuestionType: String, Equatable {
    case meaningMatch
    case fillInTheGap
    case matchSynonyms

    var label: String {
        switch self {
        case .meaningMatch: return "Meaning match"
        case .fillInTheGap: return "Fill in the gap"
        case .matchSynonyms: return "Match synonyms"
        }
    }
}

/// One placement-test question. `.fillInTheGap` uses `promptSentence` (which
/// contains a `{blank}` token swapped for the picked option); the other two
/// types show `word` on its own and `promptSentence` is nil.
struct QuizQuestion: Identifiable, Equatable {
    let id: String
    let type: QuizQuestionType
    let word: String
    let promptSentence: String?
    let options: [String]
    let correctOptionIndex: Int
    /// Same 0 (a1) ... 1 (c1+) scale as `WordTags.difficulty`, so a right/wrong
    /// answer here is directly comparable to a reel word's difficulty.
    let difficulty: Double
}
