import Foundation

/// The CEFR proficiency bands `oxford_5000` actually spans (no c2 word exists in
/// the source data), ordered lowest to highest. The single scale every word's
/// level and every user's inferred level is expressed on, so they're directly
/// comparable — replaces the old ad-hoc 0...1 `Double` encoding.
enum CEFRLevel: String, Codable, CaseIterable {
    case a1, a2, b1, b2, c1
}

extension CEFRLevel: Comparable {
    static func < (lhs: CEFRLevel, rhs: CEFRLevel) -> Bool {
        allCases.firstIndex(of: lhs)! < allCases.firstIndex(of: rhs)!
    }
}

extension CEFRLevel {
    /// Maps a `QuizQuestion.difficulty`/answer-pattern score (0...1) to the CEFR
    /// band it represents. The single source of truth both level assessors and
    /// the retest re-seed step read off of.
    static func forDifficulty(_ difficulty: Double) -> CEFRLevel {
        switch difficulty {
        case ..<0.2: return .a1
        case ..<0.4: return .a2
        case ..<0.55: return .b1
        case ..<0.7: return .b2
        default: return .c1
        }
    }

    /// The human-readable label shown wherever a user's level is surfaced —
    /// the quiz result screen and the profile screen alike, so both read the
    /// same wording for the same band.
    var displayTitle: String {
        switch self {
        case .a1: return "Beginner (A1)"
        case .a2: return "Elementary (A2)"
        case .b1: return "Intermediate (B1)"
        case .b2: return "Upper Intermediate (B2)"
        case .c1: return "Advanced (C1)"
        }
    }

    /// The band a placement-test run demonstrates: walk up from a1, and stop
    /// at the first band where the learner didn't get at least half its
    /// questions right. Deliberately *not* "the hardest question answered
    /// correctly" — that reads a single lucky guess on a late question as
    /// mastery of everything below it, even when the learner missed most of
    /// the easier ones. Requiring each band in sequence to be cleared means a
    /// gap at a1/a2 caps the result there no matter what happens later.
    static func assessed(from answers: [QuizAnswerRecord]) -> CEFRLevel {
        let answersByBand = Dictionary(grouping: answers) { forDifficulty($0.question.difficulty) }

        var assessed = CEFRLevel.a1
        for band in allCases {
            guard let bandAnswers = answersByBand[band], !bandAnswers.isEmpty else { continue }
            let correctCount = bandAnswers.filter(\.isCorrect).count
            guard Double(correctCount) / Double(bandAnswers.count) >= 0.5 else { break }
            assessed = band
        }
        return assessed
    }
}
