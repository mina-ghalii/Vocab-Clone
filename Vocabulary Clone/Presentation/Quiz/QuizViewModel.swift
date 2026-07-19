import Foundation
import Observation

/// Drives the placement-test screen: current question, the selected answer
/// (kept on screen for `answerRevealDelay` so the user can see whether it was
/// right before the view auto-advances), and the final AI-assessed result.
@Observable
final class QuizViewModel {
    private(set) var questions: [QuizQuestion]
    private(set) var currentIndex = 0
    private(set) var selectedOptionIndex: Int?
    private(set) var answers: [QuizAnswerRecord] = []
    private(set) var result: QuizResult?
    private(set) var isAssessing = false
    /// True once `generateQuestions()` has finished (generated or fell back
    /// to the static bank). The view withholds the quiz screen entirely
    /// until this flips, so it never flashes the static bank and then swaps
    /// to a generated set mid-glance.
    private(set) var hasLoadedQuestions = false

    private let questionGenerator: QuizQuestionGenerating
    private let wordPoolLoader: () async -> [QuizWordCandidate]
    private let levelAssessor: VocabularyLevelAssessing
    private let answerRevealDelay: Duration
    private let reseeder: WordReseeding?
    private let onReseedCompleted: (() -> Void)?

    var currentQuestion: QuizQuestion { questions[currentIndex] }

    nonisolated deinit {}

    /// Fraction of the test completed, counting the current question once it's answered.
    var progress: Double {
        let answeredCount = currentIndex + (selectedOptionIndex == nil ? 0 : 1)
        return Double(answeredCount) / Double(questions.count)
    }

    init(
        questions: [QuizQuestion] = QuizQuestionBank.questions,
        questionGenerator: QuizQuestionGenerating = GeminiQuizQuestionGenerator(),
        wordPoolLoader: @escaping () async -> [QuizWordCandidate] = { await QuizWordPool.loadSample() },
        levelAssessor: VocabularyLevelAssessing = GeminiLevelAssessor(),
        answerRevealDelay: Duration = .seconds(2),
        reseeder: WordReseeding? = nil,
        onReseedCompleted: (() -> Void)? = nil
    ) {
        self.questions = questions
        self.questionGenerator = questionGenerator
        self.wordPoolLoader = wordPoolLoader
        self.levelAssessor = levelAssessor
        self.answerRevealDelay = answerRevealDelay
        self.reseeder = reseeder
        self.onReseedCompleted = onReseedCompleted
    }

    /// Loads a freshly generated question set before the test starts, so
    /// each run quizzes on different real words. Only takes effect if the
    /// user hasn't already started answering — a late-arriving generation
    /// never yanks the question set out from under an in-progress test.
    /// `hasLoadedQuestions` is set on every exit path, so the view is
    /// guaranteed to unblock even if generation is skipped or fails.
    @MainActor
    func generateQuestions() async {
        defer { hasLoadedQuestions = true }
        guard currentIndex == 0, selectedOptionIndex == nil, answers.isEmpty else { return }
        let candidates = await wordPoolLoader()
        if !candidates.isEmpty,
           let generated = try? await questionGenerator.generateQuestions(from: candidates),
           generated.count == candidates.count,
           selectedOptionIndex == nil, answers.isEmpty {
            questions = generated
        }
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
        let assessed = try? await levelAssessor.assessLevel(from: answers)
        if let assessed, let reseeder {
            try? await reseeder.reseed(signals: PersonalizationSignals(targetLevel: assessed.assessedLevel))
            onReseedCompleted?()
        }
        result = assessed
        isAssessing = false
    }
}
