import Foundation

/// One entry from the onboarding placement checklist — a real `oxford_5000` word
/// (not a made-up one) with its real CEFR band, so "does the user know this word"
/// is a direct, gradeable signal rather than a guess about an arbitrary tier.
struct PlacementWord: Codable, Equatable {
    let word: String
    let band: String
    /// Same 0 (a1) ... 1 (c1) scale as `WordTags.difficulty`, so a checklist
    /// answer and a reel word are directly comparable.
    let difficulty: Double
}

extension Array where Element == PlacementWord {
    /// The three onboarding checklist screens group adjacent CEFR bands so each
    /// screen has a similar word count; c1 stands alone as "advanced" since
    /// `oxford_5000` has no c2 band.
    var beginnerScreenWords: [PlacementWord] { filter { $0.band == "a1" || $0.band == "a2" } }
    var intermediateScreenWords: [PlacementWord] { filter { $0.band == "b1" || $0.band == "b2" } }
    var advancedScreenWords: [PlacementWord] { filter { $0.band == "c1" } }
}
