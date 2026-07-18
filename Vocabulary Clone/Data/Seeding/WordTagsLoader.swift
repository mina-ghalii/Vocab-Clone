import Foundation

/// Loads the offline word enrichment tags (`oxford_5000_tags.json`) from the bundle.
/// Separate from `JSONWordSeedSource` since tags are an optional personalization
/// input, not core seed content — a missing/unreadable tags file degrades
/// personalization gracefully rather than blocking seeding.
struct WordTagsLoader {
    enum LoadError: Error {
        case resourceNotFound
    }

    private let resourceName: String
    private let bundle: Bundle

    init(resourceName: String = "oxford_5000_tags", bundle: Bundle = .main) {
        self.resourceName = resourceName
        self.bundle = bundle
    }

    func load() throws -> [String: WordTags] {
        guard let url = bundle.url(forResource: resourceName, withExtension: "json") else {
            throw LoadError.resourceNotFound
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([String: WordTags].self, from: data)
    }
}
