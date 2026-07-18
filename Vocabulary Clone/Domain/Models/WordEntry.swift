import Foundation
import SwiftData

/// One reel card: a unique word with all of its dictionary senses.
/// Content is seeded once from `oxford_5000.json` and treated as read-only at runtime.
@Model
final class WordEntry {
    @Attribute(.unique) var id: String
    var word: String
    var ukAudioFile: String
    var usAudioFile: String
    var sortIndex: Int
    var senses: [Sense]

    init(id: String, word: String, ukAudioFile: String, usAudioFile: String, sortIndex: Int, senses: [Sense]) {
        self.id = id
        self.word = word
        self.ukAudioFile = ukAudioFile
        self.usAudioFile = usAudioFile
        self.sortIndex = sortIndex
        self.senses = senses
    }
}

extension WordEntry {
    /// The easiest CEFR band this word is attested at, read straight off its own
    /// senses (a few source rows carry a blank `cefr`, which `CEFRLevel(rawValue:)`
    /// filters out rather than treating as a level).
    var cefrLevel: CEFRLevel? {
        senses.compactMap { CEFRLevel(rawValue: $0.cefr) }.min()
    }
}
