import Foundation
import SwiftData

/// Per-user, mutable state for a `WordEntry`, kept separate from seeded content
/// so re-seeding/updating the word list can never overwrite likes/saves/seen state.
@Model
final class WordProgress {
    @Attribute(.unique) var entryId: String
    var isSeen: Bool
    var seenAt: Date?
    var isLiked: Bool
    var likedAt: Date?
    var isSaved: Bool
    var savedAt: Date?

    init(entryId: String) {
        self.entryId = entryId
        self.isSeen = false
        self.seenAt = nil
        self.isLiked = false
        self.likedAt = nil
        self.isSaved = false
        self.savedAt = nil
    }
}
