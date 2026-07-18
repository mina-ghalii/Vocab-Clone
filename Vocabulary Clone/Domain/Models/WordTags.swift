import Foundation

/// Enrichment metadata for one word, produced offline by `data/tag_oxford_5000.py`
/// from signals already present in the source data: `topics` from a keyword-lexicon
/// match against the word's own Oxford definitions/examples, `difficulty` from its
/// easiest attested CEFR sense (0 = a1 ... 1 = c1+). Shipped as
/// `oxford_5000_tags.json`, keyed by word text — matches `WordEntry.word`/`WordEntry.id`.
///
/// Only these two fields — no more, no less: `PersonalizedWordOrderer` is the sole
/// reader, and it only ever asks for `topics` (the preferred-topic partition) and
/// `difficulty` (the at-or-above-level filter).
struct WordTags: Codable {
    let topics: [String]
    let difficulty: Double
}
