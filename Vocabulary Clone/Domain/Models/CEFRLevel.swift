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
