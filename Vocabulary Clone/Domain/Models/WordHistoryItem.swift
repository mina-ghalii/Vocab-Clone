import Foundation

/// Pairs a seeded `WordEntry` with its per-user `WordProgress` for display in a
/// list screen (history/favorites/saved words), plus whichever timestamp is
/// relevant to that list (seenAt/likedAt/savedAt).
struct WordHistoryItem: Identifiable {
    var id: String { entry.id }
    let entry: WordEntry
    let progress: WordProgress
    let date: Date?
}
