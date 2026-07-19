import Foundation

/// A fixed, hand-picked set of ten placement-test questions spanning a1
/// through c1, in ascending difficulty. Every word and its CEFR band is
/// pulled straight from `oxford_5000.json` (two words per band) so the
/// `difficulty` value below is grounded in the same data `WordEntry.cefrLevel`
/// reads from, rather than a guessed scale. Mixing all three question types
/// across the run (rather than one type per band) means a wrong answer on an
/// easy word is as informative as a right answer on a hard one, which is what
/// lets `VocabularyLevelAssessing` read a real level out of the pattern
/// instead of just a raw score.
enum QuizQuestionBank {
    static let questions: [QuizQuestion] = [
        QuizQuestion(
            id: "afraid",
            type: .meaningMatch,
            word: "afraid",
            promptSentence: nil,
            options: [
                "Excited and full of energy",
                "Frightened that something bad might happen",
                "Bored and impatient",
            ],
            correctOptionIndex: 1,
            difficulty: 0.1
        ),
        QuizQuestion(
            id: "busy",
            type: .fillInTheGap,
            word: "busy",
            promptSentence: "I can't talk right now, I'm really {blank} at work today.",
            options: ["clean", "busy", "cold"],
            correctOptionIndex: 1,
            difficulty: 0.18
        ),
        QuizQuestion(
            id: "brilliant",
            type: .matchSynonyms,
            word: "brilliant",
            promptSentence: nil,
            options: ["dull", "impressive", "ordinary"],
            correctOptionIndex: 1,
            difficulty: 0.25
        ),
        QuizQuestion(
            id: "ancient",
            type: .meaningMatch,
            word: "ancient",
            promptSentence: nil,
            options: [
                "Belonging to a period of history thousands of years in the past",
                "Extremely modern and fashionable",
                "Happening only once in a while",
            ],
            correctOptionIndex: 0,
            difficulty: 0.35
        ),
        QuizQuestion(
            id: "annoyed",
            type: .fillInTheGap,
            word: "annoyed",
            promptSentence: "He was getting more {blank} with me about my carelessness.",
            options: ["aware", "calm", "annoyed"],
            correctOptionIndex: 2,
            difficulty: 0.42
        ),
        QuizQuestion(
            id: "brave",
            type: .matchSynonyms,
            word: "brave",
            promptSentence: nil,
            options: ["courageous", "careless", "aged"],
            correctOptionIndex: 0,
            difficulty: 0.5
        ),
        QuizQuestion(
            id: "anxious",
            type: .meaningMatch,
            word: "anxious",
            promptSentence: nil,
            options: [
                "Feeling worried or nervous",
                "Feeling extremely proud of an achievement",
                "Showing no interest in what is happening",
            ],
            correctOptionIndex: 0,
            difficulty: 0.58
        ),
        QuizQuestion(
            id: "ashamed",
            type: .fillInTheGap,
            word: "ashamed",
            promptSentence: "She was deeply {blank} of her behaviour at the party.",
            options: ["artistic", "adequate", "ashamed"],
            correctOptionIndex: 2,
            difficulty: 0.68
        ),
        QuizQuestion(
            id: "absurd",
            type: .matchSynonyms,
            word: "absurd",
            promptSentence: nil,
            options: ["ridiculous", "logical", "accountable"],
            correctOptionIndex: 0,
            difficulty: 0.78
        ),
        QuizQuestion(
            id: "arbitrary",
            type: .meaningMatch,
            word: "arbitrary",
            promptSentence: nil,
            options: [
                "Showing great skill gained through years of experience",
                "Not based on any clear reason or system",
                "Related to the design of buildings",
            ],
            correctOptionIndex: 1,
            difficulty: 0.9
        ),
    ]
}
