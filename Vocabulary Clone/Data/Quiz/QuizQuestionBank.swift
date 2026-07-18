import Foundation

/// A fixed, hand-picked set of ten placement-test questions spanning a2
/// through c1+, in ascending difficulty. Mixing all three question types at
/// every band (rather than one type per band) means a wrong answer on an easy
/// word is as informative as a right answer on a hard one, which is what lets
/// `VocabularyLevelAssessing` read a real level out of the pattern instead of
/// just a raw score.
enum QuizQuestionBank {
    static let questions: [QuizQuestion] = [
        QuizQuestion(
            id: "reluctant",
            type: .meaningMatch,
            word: "reluctant",
            promptSentence: nil,
            options: [
                "Extremely happy and excited about a plan",
                "Unwilling or hesitant to do something",
                "Loud and difficult to ignore",
            ],
            correctOptionIndex: 1,
            difficulty: 0.15
        ),
        QuizQuestion(
            id: "elated",
            type: .fillInTheGap,
            word: "elated",
            promptSentence: "She felt {blank} after hearing the good news.",
            options: ["elated", "sedentary", "gullible"],
            correctOptionIndex: 0,
            difficulty: 0.2
        ),
        QuizQuestion(
            id: "candid",
            type: .matchSynonyms,
            word: "candid",
            promptSentence: nil,
            options: ["hidden", "colorful", "honest"],
            correctOptionIndex: 2,
            difficulty: 0.3
        ),
        QuizQuestion(
            id: "meticulous",
            type: .meaningMatch,
            word: "meticulous",
            promptSentence: nil,
            options: [
                "Showing great care and attention to detail",
                "Feeling extremely tired and worn out",
                "Happening completely by chance",
            ],
            correctOptionIndex: 0,
            difficulty: 0.4
        ),
        QuizQuestion(
            id: "skeptical",
            type: .fillInTheGap,
            word: "skeptical",
            promptSentence: "The detective remained {blank} despite the confusing evidence.",
            options: ["gregarious", "skeptical", "insipid"],
            correctOptionIndex: 1,
            difficulty: 0.45
        ),
        QuizQuestion(
            id: "audacious",
            type: .matchSynonyms,
            word: "audacious",
            promptSentence: nil,
            options: ["bold", "quiet", "fragile"],
            correctOptionIndex: 0,
            difficulty: 0.55
        ),
        QuizQuestion(
            id: "ephemeral",
            type: .meaningMatch,
            word: "ephemeral",
            promptSentence: nil,
            options: [
                "Extremely heavy or dense",
                "Related to the study of insects",
                "Lasting for a very short time",
            ],
            correctOptionIndex: 2,
            difficulty: 0.65
        ),
        QuizQuestion(
            id: "acerbic",
            type: .fillInTheGap,
            word: "acerbic",
            promptSentence: "His {blank} remarks alienated most of his colleagues.",
            options: ["verdant", "tacit", "acerbic"],
            correctOptionIndex: 2,
            difficulty: 0.75
        ),
        QuizQuestion(
            id: "obdurate",
            type: .matchSynonyms,
            word: "obdurate",
            promptSentence: nil,
            options: ["generous", "transparent", "stubborn"],
            correctOptionIndex: 2,
            difficulty: 0.85
        ),
        QuizQuestion(
            id: "nadir",
            type: .meaningMatch,
            word: "nadir",
            promptSentence: nil,
            options: [
                "A magical drink that can do wonders",
                "The lowest point or worst moment of something",
                "Denial of comfort to oneself",
            ],
            correctOptionIndex: 1,
            difficulty: 0.95
        ),
    ]
}
