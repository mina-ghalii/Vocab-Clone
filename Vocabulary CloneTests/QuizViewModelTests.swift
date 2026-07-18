import XCTest
@testable import Vocabulary_Clone

@MainActor
final class QuizViewModelTests: XCTestCase {
    private func makeQuestions(count: Int) -> [QuizQuestion] {
        (0..<count).map { index in
            QuizQuestion(
                id: "q\(index)",
                type: .meaningMatch,
                word: "word\(index)",
                promptSentence: nil,
                options: ["correct", "wrong1", "wrong2"],
                correctOptionIndex: 0,
                difficulty: Double(index) / Double(count)
            )
        }
    }

    func testInitialStateStartsAtFirstQuestionWithNoSelection() {
        let viewModel = QuizViewModel(
            questions: makeQuestions(count: 3),
            levelAssessor: FakeLevelAssessor(),
            answerRevealDelay: .seconds(5)
        )

        XCTAssertEqual(viewModel.currentIndex, 0)
        XCTAssertNil(viewModel.selectedOptionIndex)
        XCTAssertEqual(viewModel.progress, 0)
    }

    func testSelectAnswerRecordsCorrectnessAndUpdatesProgress() {
        let viewModel = QuizViewModel(
            questions: makeQuestions(count: 3),
            levelAssessor: FakeLevelAssessor(),
            answerRevealDelay: .seconds(5)
        )

        viewModel.selectAnswer(0)

        XCTAssertEqual(viewModel.selectedOptionIndex, 0)
        XCTAssertEqual(viewModel.answers.count, 1)
        XCTAssertTrue(viewModel.answers[0].isCorrect)
        XCTAssertEqual(viewModel.progress, 1.0 / 3.0, accuracy: 0.0001)
    }

    func testSelectAnswerRecordsIncorrectChoice() {
        let viewModel = QuizViewModel(
            questions: makeQuestions(count: 3),
            levelAssessor: FakeLevelAssessor(),
            answerRevealDelay: .seconds(5)
        )

        viewModel.selectAnswer(1)

        XCTAssertFalse(viewModel.answers[0].isCorrect)
        XCTAssertEqual(viewModel.answers[0].selectedOptionIndex, 1)
    }

    func testSelectingASecondTimeBeforeAdvanceIsIgnored() {
        let viewModel = QuizViewModel(
            questions: makeQuestions(count: 3),
            levelAssessor: FakeLevelAssessor(),
            answerRevealDelay: .seconds(5)
        )

        viewModel.selectAnswer(0)
        viewModel.selectAnswer(1)

        XCTAssertEqual(viewModel.selectedOptionIndex, 0)
        XCTAssertEqual(viewModel.answers.count, 1)
    }

    func testAdvancesToNextQuestionAfterRevealDelay() async throws {
        let viewModel = QuizViewModel(
            questions: makeQuestions(count: 3),
            levelAssessor: FakeLevelAssessor(),
            answerRevealDelay: .milliseconds(10)
        )

        viewModel.selectAnswer(1)
        try await Task.sleep(for: .milliseconds(200))

        XCTAssertEqual(viewModel.currentIndex, 1)
        XCTAssertNil(viewModel.selectedOptionIndex)
        XCTAssertNil(viewModel.result)
    }

    func testFinishesAndAssessesLevelAfterLastQuestion() async throws {
        let assessor = FakeLevelAssessor()
        assessor.resultToReturn = QuizResult(correctCount: 1, totalCount: 1, levelTitle: "Advanced (C1)", summary: "great job")
        let viewModel = QuizViewModel(
            questions: makeQuestions(count: 1),
            levelAssessor: assessor,
            answerRevealDelay: .milliseconds(10)
        )

        viewModel.selectAnswer(0)
        try await Task.sleep(for: .milliseconds(200))

        XCTAssertEqual(viewModel.result, assessor.resultToReturn)
        XCTAssertEqual(assessor.assessLevelCallCount, 1)
        XCTAssertEqual(assessor.lastAnswers.count, 1)
        XCTAssertFalse(viewModel.isAssessing)
    }

    func testResultStaysNilWhenLevelAssessorThrows() async throws {
        let assessor = FakeLevelAssessor()
        assessor.errorToThrow = NSError(domain: "test", code: 1)
        let viewModel = QuizViewModel(
            questions: makeQuestions(count: 1),
            levelAssessor: assessor,
            answerRevealDelay: .milliseconds(10)
        )

        viewModel.selectAnswer(0)
        try await Task.sleep(for: .milliseconds(200))

        XCTAssertNil(viewModel.result)
        XCTAssertFalse(viewModel.isAssessing)
    }

    func testProgressCountsCurrentQuestionOnceAnswered() {
        let viewModel = QuizViewModel(
            questions: makeQuestions(count: 4),
            levelAssessor: FakeLevelAssessor(),
            answerRevealDelay: .seconds(5)
        )

        XCTAssertEqual(viewModel.progress, 0)
        viewModel.selectAnswer(0)
        XCTAssertEqual(viewModel.progress, 0.25)
    }
}
