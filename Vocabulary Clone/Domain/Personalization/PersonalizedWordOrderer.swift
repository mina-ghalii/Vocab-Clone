import Foundation

/// Orders freshly-loaded `WordEntry` values for a specific user, then reassigns
/// `sortIndex` to the resulting dense 0..n-1 order. Pure and side-effect-free
/// apart from that mutation, so it's unit-testable without SwiftData —
/// `ReelViewModel`/`SwiftDataWordRepository` need no changes since they already
/// just walk `sortIndex` ascending.
///
/// The rule, in order:
/// 1. Words already asked about in the placement checklist are dropped — the
///    app already knows the answer, no need to show them again.
/// 2. Words at or above the inferred level come first; anything below is a
///    shuffled tail so the reel never truly runs dry for an advanced user.
/// 3. Within "at or above level", words matching a preferred topic are shuffled
///    to the front; once those run out the rest of the eligible words continue
///    (also shuffled), rather than the reel just stopping.
enum PersonalizedWordOrderer {
    static func order(
        _ entries: [WordEntry],
        tags: [String: WordTags],
        signals: PersonalizationSignals,
        preferredTopics: Set<String>,
        excludedWords: Set<String>
    ) -> [WordEntry] {
        let candidates = entries.filter { !excludedWords.contains($0.word) }

        let (atOrAboveLevel, belowLevel) = candidates.partitioned { entry in
            (entry.cefrLevel ?? signals.targetLevel) >= signals.targetLevel
        }

        let (topicMatched, rest) = atOrAboveLevel.partitioned { entry in
            guard !preferredTopics.isEmpty, let wordTopics = tags[entry.word]?.topics else { return false }
            return !Set(wordTopics).isDisjoint(with: preferredTopics)
        }

        let ordered = topicMatched.shuffled() + rest.shuffled() + belowLevel.shuffled()

        for (index, entry) in ordered.enumerated() {
            entry.sortIndex = index
        }
        return ordered
    }
}

private extension Array {
    /// Splits into (matching, non-matching), preserving each element's relative order.
    func partitioned(by matches: (Element) -> Bool) -> (matching: [Element], nonMatching: [Element]) {
        var matching: [Element] = []
        var nonMatching: [Element] = []
        for element in self {
            if matches(element) {
                matching.append(element)
            } else {
                nonMatching.append(element)
            }
        }
        return (matching, nonMatching)
    }
}
