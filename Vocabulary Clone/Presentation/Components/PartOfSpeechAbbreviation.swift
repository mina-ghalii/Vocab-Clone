/// Maps the 17 distinct `type` values found in oxford_5000.json to the
/// short form shown on a word card, e.g. "adjective" → "adj.".
enum PartOfSpeechAbbreviation {
    private static let abbreviations: [String: String] = [
        "noun": "n.",
        "verb": "v.",
        "adjective": "adj.",
        "adverb": "adv.",
        "pronoun": "pron.",
        "preposition": "prep.",
        "determiner": "det.",
        "number": "num.",
        "conjunction": "conj.",
        "exclamation": "excl.",
        "modal verb": "modal v.",
        "ordinal number": "ord. num.",
        "auxiliary verb": "aux. v.",
        "linking verb": "linking v.",
        "indefinite article": "article",
        "definite article": "article",
        "infinitive marker": "infinitive"
    ]

    static func abbreviate(_ partOfSpeech: String) -> String {
        abbreviations[partOfSpeech] ?? partOfSpeech
    }
}
