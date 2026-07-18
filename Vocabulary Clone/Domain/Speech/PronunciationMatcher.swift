import Foundation

/// Decides whether a speech transcript counts as a correct attempt at a target
/// word. Deliberately lenient: this validates "did the user say the word,"
/// not pronunciation quality, so small transcription noise (trailing filler,
/// punctuation, a one-letter slip) shouldn't fail an otherwise-correct answer.
enum PronunciationMatcher {
    static func isMatch(transcript: String, target: String) -> Bool {
        let normalizedTarget = normalize(target)
        guard !normalizedTarget.isEmpty else { return false }

        let words = normalize(transcript).split(separator: " ").map(String.init)
        return words.contains { word in
            word == normalizedTarget || levenshteinDistance(word, normalizedTarget) <= tolerance(for: normalizedTarget)
        }
    }

    /// Very short words (e.g. "at", "in") get zero tolerance — a one-letter
    /// edit there is likely a different real word, not transcription noise.
    private static func tolerance(for word: String) -> Int {
        word.count <= 3 ? 0 : 1
    }

    private static func normalize(_ text: String) -> String {
        text
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .components(separatedBy: CharacterSet.letters.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private static func levenshteinDistance(_ lhs: String, _ rhs: String) -> Int {
        let a = Array(lhs)
        let b = Array(rhs)
        var distances = Array(0...b.count)

        for i in 1...max(a.count, 1) where !a.isEmpty {
            var previousDiagonal = distances[0]
            distances[0] = i
            for j in 1...b.count {
                let previousUp = distances[j]
                distances[j] = a[i - 1] == b[j - 1]
                    ? previousDiagonal
                    : 1 + min(previousDiagonal, previousUp, distances[j - 1])
                previousDiagonal = previousUp
            }
        }

        return a.isEmpty ? b.count : distances[b.count]
    }
}
