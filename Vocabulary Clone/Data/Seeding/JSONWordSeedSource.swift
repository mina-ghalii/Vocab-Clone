import Foundation

/// Decodes `oxford_5000.json` (a dictionary of dictionary-entry objects, one per
/// word sense) and groups senses that share the same `word` into a single
/// `WordEntry`, preserving the original JSON ordering as `sortIndex`.
struct JSONWordSeedSource: WordSeedProviding {
    enum SeedError: Error {
        case resourceNotFound
    }

    private let resourceName: String
    private let bundle: Bundle

    init(resourceName: String = "oxford_5000", bundle: Bundle = .main) {
        self.resourceName = resourceName
        self.bundle = bundle
    }

    func loadEntries() throws -> [WordEntry] {
        guard let url = bundle.url(forResource: resourceName, withExtension: "json") else {
            throw SeedError.resourceNotFound
        }

        let data = try Data(contentsOf: url)
        let raw = try JSONDecoder().decode([String: RawWordEntry].self, from: data)
        let orderedEntries = raw
            .sorted { (Int($0.key) ?? 0) < (Int($1.key) ?? 0) }
            .map(\.value)

        var wordOrder: [String] = []
        var sensesByWord: [String: [Sense]] = [:]
        var audioByWord: [String: (uk: String, us: String)] = [:]

        for entry in orderedEntries {
            guard !entry.word.trimmingCharacters(in: .whitespaces).isEmpty else { continue }
            if sensesByWord[entry.word] == nil {
                wordOrder.append(entry.word)
                audioByWord[entry.word] = (entry.uk, entry.us)
            }
            let sense = Sense(
                partOfSpeech: entry.type,
                cefr: entry.cefr,
                phonBr: entry.phon_br,
                phonNAm: entry.phon_n_am,
                definition: entry.definition,
                example: entry.example
            )
            sensesByWord[entry.word, default: []].append(sense)
        }

        return wordOrder.enumerated().map { index, word in
            let audio = audioByWord[word]!
            return WordEntry(
                id: word,
                word: word,
                ukAudioFile: audio.uk,
                usAudioFile: audio.us,
                sortIndex: index,
                senses: sensesByWord[word] ?? []
            )
        }
    }
}

private struct RawWordEntry: Codable {
    let word: String
    let type: String
    let cefr: String
    let phon_br: String
    let phon_n_am: String
    let definition: String
    let example: String
    let uk: String
    let us: String
}
