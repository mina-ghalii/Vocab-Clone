/// Populates the local store from the bundled word list, exactly once.
protocol WordSeeding {
    func seedIfNeeded() async throws
}

/// Abstraction over where seed content comes from (JSON today, could be anything later)
/// so `DataSeedingService` never depends on a concrete file format.
protocol WordSeedProviding {
    func loadEntries() throws -> [WordEntry]
}
