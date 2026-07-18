import XCTest
@testable import Vocabulary_Clone

final class QuizQuestionBankTests: XCTestCase {
    private var questions: [QuizQuestion] { QuizQuestionBank.questions }

    func testContainsTenQuestions() {
        XCTAssertEqual(questions.count, 10)
    }

    func testIdsAreUnique() {
        XCTAssertEqual(Set(questions.map(\.id)).count, questions.count)
    }

    func testDifficultiesAreStrictlyAscending() {
        let difficulties = questions.map(\.difficulty)

        XCTAssertEqual(difficulties, difficulties.sorted())
        XCTAssertEqual(Set(difficulties).count, difficulties.count)
    }

    func testEveryQuestionHasAValidCorrectOptionIndex() {
        for question in questions {
            XCTAssertTrue(
                question.options.indices.contains(question.correctOptionIndex),
                "question \(question.id) has an out-of-range correctOptionIndex"
            )
        }
    }

    func testEveryQuestionHasAtLeastTwoOptions() {
        for question in questions {
            XCTAssertGreaterThanOrEqual(question.options.count, 2, "question \(question.id)")
        }
    }

    func testFillInTheGapQuestionsEmbedTheirWordAsTheCorrectOption() {
        for question in questions where question.type == .fillInTheGap {
            XCTAssertNotNil(question.promptSentence, "question \(question.id)")
            XCTAssertTrue(question.promptSentence?.contains("{blank}") ?? false, "question \(question.id)")
            XCTAssertEqual(question.options[question.correctOptionIndex], question.word, "question \(question.id)")
        }
    }

    func testNonFillInTheGapQuestionsHaveNoPromptSentence() {
        for question in questions where question.type != .fillInTheGap {
            XCTAssertNil(question.promptSentence, "question \(question.id)")
        }
    }
}
