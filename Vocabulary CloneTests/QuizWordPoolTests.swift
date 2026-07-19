import XCTest
@testable import Vocabulary_Clone

final class QuizWordPoolTests: XCTestCase {
    func testSampleReturnsTwoRealWordsPerBandInAscendingOrder() throws {
        let pool = try QuizWordPool()

        let sample = pool.sample()

        XCTAssertEqual(sample.count, 10)
        XCTAssertEqual(sample.map(\.band), [.a1, .a1, .a2, .a2, .b1, .b1, .b2, .b2, .c1, .c1])
        for candidate in sample {
            XCTAssertFalse(candidate.word.isEmpty)
            XCTAssertFalse(candidate.definition.isEmpty)
        }
    }

    func testSampleDifficultiesAreStrictlyAscending() throws {
        let pool = try QuizWordPool()

        let difficulties = pool.sample().map(\.difficulty)

        XCTAssertEqual(difficulties, difficulties.sorted())
        XCTAssertEqual(Set(difficulties).count, difficulties.count)
    }

    func testSampleVariesAcrossCalls() throws {
        let pool = try QuizWordPool()

        let samples = (0..<10).map { _ in pool.sample().map(\.word) }

        XCTAssertTrue(Set(samples).count > 1, "expected repeated sampling to eventually produce a different word list")
    }
}
