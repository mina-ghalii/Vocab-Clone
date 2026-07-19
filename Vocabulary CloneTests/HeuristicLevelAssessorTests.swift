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
        XCTAssertEqual(result.assessedLevel, .a1)
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
        XCTAssertEqual(result.assessedLevel, .b1)
        XCTAssertEqual(result.levelTitle, "Intermediate (B1)")
    }

    func testDifficultyBandBoundaries() async throws {
        let cases: [(difficulty: Double, expectedLevel: CEFRLevel, expectedTitle: String)] = [
            (0.0, .a1, "Beginner (A1)"),
            (0.19, .a1, "Beginner (A1)"),
            (0.2, .a2, "Elementary (A2)"),
            (0.39, .a2, "Elementary (A2)"),
            (0.4, .b1, "Intermediate (B1)"),
            (0.54, .b1, "Intermediate (B1)"),
            (0.55, .b2, "Upper Intermediate (B2)"),
            (0.69, .b2, "Upper Intermediate (B2)"),
            (0.7, .c1, "Advanced (C1)"),
            (1.0, .c1, "Advanced (C1)"),
        ]

        for testCase in cases {
            let result = try await HeuristicLevelAssessor().assessLevel(
                from: [makeAnswer(difficulty: testCase.difficulty, isCorrect: true)]
            )
            XCTAssertEqual(result.assessedLevel, testCase.expectedLevel, "difficulty \(testCase.difficulty)")
            XCTAssertEqual(result.levelTitle, testCase.expectedTitle, "difficulty \(testCase.difficulty)")
        }
    }

    func testNineOfTenCorrectWithOnlyAHighDifficultyMissAssessesC1() async throws {
        // Mirrors QuizQuestionBank/QuizWordPool's real ladder: two questions
        // per band, a1 through c1, ascending.
        let ladder: [Double] = [0.1, 0.18, 0.25, 0.35, 0.42, 0.5, 0.58, 0.68, 0.78, 0.9]
        let answers = ladder.map { makeAnswer(difficulty: $0, isCorrect: $0 != 0.9) }

        let result = try await HeuristicLevelAssessor().assessLevel(from: answers)

        XCTAssertEqual(result.correctCount, 9)
        XCTAssertEqual(result.assessedLevel, .c1)
    }

    func testFiveOfTenCorrectWithAGapAtTheBottomDoesNotAssessC1() async throws {
        // Same ladder, but both a1 questions and both b1 questions are wrong
        // — a real gap at the bottom — even though one of the two hardest
        // (c1) questions was guessed correctly. The old
        // "highest-correct-difficulty" heuristic read this as C1; the fix
        // should cap it at the first band that wasn't cleared.
        let ladder: [Double] = [0.1, 0.18, 0.25, 0.35, 0.42, 0.5, 0.58, 0.68, 0.78, 0.9]
        let wrong: Set<Double> = [0.1, 0.18, 0.42, 0.5, 0.9]
        let answers = ladder.map { makeAnswer(difficulty: $0, isCorrect: !wrong.contains($0)) }

        let result = try await HeuristicLevelAssessor().assessLevel(from: answers)

        XCTAssertEqual(result.correctCount, 5)
        XCTAssertEqual(result.assessedLevel, .a1)
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
