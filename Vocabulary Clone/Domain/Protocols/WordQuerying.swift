/// Read-only access to seeded word content, windowed by `sortIndex` so callers
/// never need to fetch the entire word list into memory at once.
protocol WordQuerying {
    func word(at sortIndex: Int) async throws -> WordEntry?
    func words(from sortIndex: Int, limit: Int) async throws -> [WordEntry]
    func totalCount() async throws -> Int
    func resumeIndex() async throws -> Int
}
