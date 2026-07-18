/// Mutations to per-user word state (seen/liked/saved) and reel resume position.
protocol WordStateMutating {
    func markSeen(entryId: String) async throws
    func toggleLiked(entryId: String) async throws -> Bool
    func toggleSaved(entryId: String) async throws -> Bool
    func setResumeIndex(_ index: Int) async throws
    func progress(for entryId: String) async throws -> WordProgress
}
