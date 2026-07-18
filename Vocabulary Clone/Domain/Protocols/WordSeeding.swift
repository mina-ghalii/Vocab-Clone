/// Populates the local store from the bundled word list, exactly once.
protocol WordSeeding {
    func seedIfNeeded() async throws
}

/// Abstraction over where seed content comes from (JSON today, could be anything later)
/// so `DataSeedingService` never depends on a concrete file format.
protocol WordSeedProviding {
    func loadEntries() throws -> [WordEntry]
}

/// Re-derives personalized order for words already seeded into the store,
/// unlike `WordSeeding`, which only ever runs once against an empty store.
protocol WordReseeding {
    func reseed(signals: PersonalizationSignals) async throws
}
