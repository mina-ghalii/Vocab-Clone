import Foundation

/// A single dictionary sense (one part-of-speech + definition) belonging to a `WordEntry`.
/// Embedded rather than modeled as its own `@Model` — senses are immutable seeded content
/// that is only ever read alongside its parent word, never queried independently.
struct Sense: Codable, Hashable {
    let partOfSpeech: String
    let cefr: String
    let phonBr: String
    let phonNAm: String
    let definition: String
    let example: String
}
