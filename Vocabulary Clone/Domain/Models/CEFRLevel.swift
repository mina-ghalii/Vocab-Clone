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
}
