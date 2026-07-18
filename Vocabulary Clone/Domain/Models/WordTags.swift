import Foundation

/// Enrichment metadata for one word, produced offline by `data/tag_oxford_5000.py`
/// from a keyword-lexicon match against the word's own Oxford definitions/examples.
/// Lives as a `topics` field on each sense entry in `oxford_5000.json` (identical
/// across every sense of a given word); `WordTagsLoader` collapses those down to
/// one `WordTags` per headword, matching `WordEntry.word`/`WordEntry.id`.
///
/// `PersonalizedWordOrderer` is the sole reader, and it only ever asks for
/// `topics` (the preferred-topic partition).
struct WordTags: Codable {
    let topics: [String]
}
