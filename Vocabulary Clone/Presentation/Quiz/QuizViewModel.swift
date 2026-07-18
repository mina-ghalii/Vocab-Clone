import Foundation
import Observation

/// Drives the placement-test screen: current question, the selected answer
/// (kept on screen for `answerRevealDelay` so the user can see whether it was
/// right before the view auto-advances), and the final AI-assessed result.
@Observable
final class QuizViewModel {
    let questions: [QuizQuestion]
    private(set) var currentIndex = 0
    private(set) var selectedOptionIndex: Int?
    private(set) var answers: [QuizAnswerRecord] = []
    private(set) var result: QuizResult?
    private(set) var isAssessing = false

    private let levelAssessor: VocabularyLevelAssessing
    private let answerRevealDelay: Duration

    var currentQuestion: QuizQuestion { questions[currentIndex] }

    nonisolated deinit {}

    /// Fraction of the test completed, counting the current question once it's answered.
    var progress: Double {
        let answeredCount = currentIndex + (selectedOptionIndex == nil ? 0 : 1)
        return Double(answeredCount) / Double(questions.count)
    }

    init(
        questions: [QuizQuestion] = QuizQuestionBank.questions,
        levelAssessor: VocabularyLevelAssessing = AppleIntelligenceLevelAssessor(),
        answerRevealDelay: Duration = .seconds(2)
    ) {
        self.questions = questions
        self.levelAssessor = levelAssessor
        self.answerRevealDelay = answerRevealDelay
    }

    func selectAnswer(_ index: Int) {
        guard selectedOptionIndex == nil else { return }

        let question = currentQuestion
        selectedOptionIndex = index
        answers.append(QuizAnswerRecord(question: question, selectedOptionIndex: index, isCorrect: index == question.correctOptionIndex))

        Task {
            try? await Task.sleep(for: answerRevealDelay)
            await advance()
        }
    }

    @MainActor
    private func advance() async {
        guard currentIndex + 1 < questions.count else {
            await finish()
            return
        }
        currentIndex += 1
        selectedOptionIndex = nil
    }

    @MainActor
    private func finish() async {
        isAssessing = true
        result = try? await levelAssessor.assessLevel(from: answers)
        isAssessing = false
    }
}
