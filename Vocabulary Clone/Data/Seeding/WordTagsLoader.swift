import Foundation

/// Loads the offline word enrichment tags — `topics`, one entry per sense —
/// from `oxford_5000.json` and collapses them down to one `WordTags` per
/// headword (every sense of a word carries the same `topics`, so any one of
/// them will do). Goes through its own decode of the shared file, rather than
/// reusing `JSONWordSeedSource`'s, so a missing/unreadable file degrades
/// personalization gracefully instead of blocking seeding.
struct WordTagsLoader {
    enum LoadError: Error {
        case resourceNotFound
    }

    private let resourceName: String
    private let bundle: Bundle

    init(resourceName: String = "oxford_5000", bundle: Bundle = .main) {
        self.resourceName = resourceName
        self.bundle = bundle
    }

    func load() throws -> [String: WordTags] {
        guard let url = bundle.url(forResource: resourceName, withExtension: "json") else {
            throw LoadError.resourceNotFound
        }
        let data = try Data(contentsOf: url)
        let raw = try JSONDecoder().decode([String: RawTaggedWord].self, from: data)
        return raw.values.reduce(into: [:]) { result, entry in
            result[entry.word] = WordTags(topics: entry.topics)
        }
    }
}

private struct RawTaggedWord: Codable {
    let word: String
    let topics: [String]
}
