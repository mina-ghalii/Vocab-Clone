import Foundation

/// Loads the onboarding placement checklist (`onboarding_placement_words.json`,
/// generated offline by `data/generate_placement_words.py`) from the bundle.
struct PlacementWordsLoader {
    enum LoadError: Error {
        case resourceNotFound
    }

    private let resourceName: String
    private let bundle: Bundle

    init(resourceName: String = "onboarding_placement_words", bundle: Bundle = .main) {
        self.resourceName = resourceName
        self.bundle = bundle
    }

    func load() throws -> [PlacementWord] {
        guard let url = bundle.url(forResource: resourceName, withExtension: "json") else {
            throw LoadError.resourceNotFound
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(PlacementWordsFile.self, from: data).words
    }
}

private struct PlacementWordsFile: Codable {
    let words: [PlacementWord]
}
