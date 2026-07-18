import XCTest
@testable import Vocabulary_Clone

final class HeuristicLevelAssessorTests: XCTestCase {
    private func makeAnswer(difficulty: Double, isCorrect: Bool) -> QuizAnswerRecord {
        let question = QuizQuestion(
            id: UUID().uuidString,
            type: .meaningMatch,
            word: "word",
            promptSentence: nil,
            options: ["right", "wrong"],
            correctOptionIndex: 0,
            difficulty: difficulty
        )
        return QuizAnswerRecord(
            question: question,
            selectedOptionIndex: isCorrect ? 0 : 1,
            isCorrect: isCorrect
        )
    }

    func testNoAnswersYieldsBeginnerLevel() async throws {
        let result = try await HeuristicLevelAssessor().assessLevel(from: [])

        XCTAssertEqual(result.correctCount, 0)
        XCTAssertEqual(result.totalCount, 0)
        XCTAssertEqual(result.levelTitle, "Beginner (A1)")
    }

    func testLevelIsDrivenByHighestCorrectDifficultyNotHighestAttempted() async throws {
        let answers = [
            makeAnswer(difficulty: 0.1, isCorrect: true),
            makeAnswer(difficulty: 0.9, isCorrect: false),
            makeAnswer(difficulty: 0.5, isCorrect: true),
        ]

        let result = try await HeuristicLevelAssessor().assessLevel(from: answers)

        XCTAssertEqual(result.correctCount, 2)
        XCTAssertEqual(result.totalCount, 3)
        XCTAssertEqual(result.levelTitle, "Intermediate (B1)")
    }

    func testDifficultyBandBoundaries() async throws {
        let cases: [(difficulty: Double, expectedLevel: String)] = [
            (0.0, "Beginner (A1)"),
            (0.19, "Beginner (A1)"),
            (0.2, "Elementary (A2)"),
            (0.39, "Elementary (A2)"),
            (0.4, "Intermediate (B1)"),
            (0.54, "Intermediate (B1)"),
            (0.55, "Upper Intermediate (B2)"),
            (0.69, "Upper Intermediate (B2)"),
            (0.7, "Advanced (C1)"),
            (1.0, "Advanced (C1)"),
        ]

        for testCase in cases {
            let result = try await HeuristicLevelAssessor().assessLevel(
                from: [makeAnswer(difficulty: testCase.difficulty, isCorrect: true)]
            )
            XCTAssertEqual(result.levelTitle, testCase.expectedLevel, "difficulty \(testCase.difficulty)")
        }
    }

    func testSummaryIncludesCountsAndLevel() async throws {
        let answers = [
            makeAnswer(difficulty: 0.1, isCorrect: true),
            makeAnswer(difficulty: 0.2, isCorrect: false),
        ]

        let result = try await HeuristicLevelAssessor().assessLevel(from: answers)

        XCTAssertEqual(
            result.summary,
            "You answered 1 of 2 words correctly, placing you around Beginner (A1). Keep practicing to climb higher."
        )
    }
}
