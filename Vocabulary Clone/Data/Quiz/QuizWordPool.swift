import Foundation

/// Loads `oxford_5000.json` directly — independent of the SwiftData word
/// store, which may not be seeded yet the first time the placement test runs
/// — and samples a fresh pair of real adjectives per CEFR band on every call,
/// so a `QuizQuestionGenerating` implementation gets different ground-truth
/// words to write questions about each time a quiz starts.
struct QuizWordPool {
    enum PoolError: Error {
        case resourceNotFound
    }

    /// The two difficulty values assigned to a band's pair of sampled words,
    /// matching `QuizQuestionBank`'s ascending scale so a generated run and
    /// the static fallback grade on the same curve.
    private static let difficultyPairsByBand: [CEFRLevel: (Double, Double)] = [
        .a1: (0.1, 0.18),
        .a2: (0.25, 0.35),
        .b1: (0.42, 0.5),
        .b2: (0.58, 0.68),
        .c1: (0.78, 0.9),
    ]

    private let wordsByBand: [CEFRLevel: [(word: String, definition: String)]]

    init(resourceName: String = "oxford_5000", bundle: Bundle = .main) throws {
        guard let url = bundle.url(forResource: resourceName, withExtension: "json") else {
            throw PoolError.resourceNotFound
        }
        let data = try Data(contentsOf: url)
        let raw = try JSONDecoder().decode([String: RawEntry].self, from: data)

        var byBand: [CEFRLevel: [(word: String, definition: String)]] = [:]
        for entry in raw.values {
            guard entry.type == "adjective",
                  !entry.definition.trimmingCharacters(in: .whitespaces).isEmpty,
                  let band = CEFRLevel(rawValue: entry.cefr)
            else { continue }
            byBand[band, default: []].append((entry.word, entry.definition))
        }
        wordsByBand = byBand
    }

    /// Two random words per CEFR band, a1 through c1 ascending — ten
    /// candidates total, each stamped with the fixed difficulty
    /// `QuizQuestionBank` uses for that band slot.
    func sample() -> [QuizWordCandidate] {
        CEFRLevel.allCases.flatMap { band -> [QuizWordCandidate] in
            let picks = (wordsByBand[band] ?? []).shuffled().prefix(2)
            let difficulties = Self.difficultyPairsByBand[band] ?? (0, 0)
            return picks.enumerated().map { index, entry in
                QuizWordCandidate(
                    word: entry.word,
                    definition: entry.definition,
                    band: band,
                    difficulty: index == 0 ? difficulties.0 : difficulties.1
                )
            }
        }
    }

    /// Loads and samples off the main actor, so decoding the ~2MB source
    /// file never blocks the UI. The default `wordPoolLoader` `QuizViewModel` uses.
    static func loadSample() async -> [QuizWordCandidate] {
        await Task.detached(priority: .userInitiated) {
            (try? QuizWordPool())?.sample() ?? []
        }.value
    }

    private struct RawEntry: Codable {
        let word: String
        let type: String
        let cefr: String
        let definition: String
    }
}
