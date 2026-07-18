/// Read access to the user's seen/liked/saved word lists (History, Favorites,
/// Your words), each sorted most-recent-first.
protocol WordHistoryQuerying {
    func seenEntries() async throws -> [WordHistoryItem]
    func likedEntries() async throws -> [WordHistoryItem]
    func savedEntries() async throws -> [WordHistoryItem]
}
