import Foundation
import FoundationModels

/// Sends the placement-test transcript to the on-device Apple Intelligence
/// model and asks it to read a CEFR level out of the answer pattern, with
/// short, specific feedback — richer than a plain percentage score. Falls
/// back to `HeuristicLevelAssessor` when the model isn't available (device
/// unsupported, Apple Intelligence disabled, or the download hasn't finished).
struct AppleIntelligenceLevelAssessor: VocabularyLevelAssessing {
    private let fallback: VocabularyLevelAssessing = HeuristicLevelAssessor()

    func assessLevel(from answers: [QuizAnswerRecord]) async throws -> QuizResult {
        guard case .available = SystemLanguageModel.default.availability else {
            return try await fallback.assessLevel(from: answers)
        }

        let correctCount = answers.filter(\.isCorrect).count
        let transcript = answers
            .map { "\($0.question.word) (difficulty \(String(format: "%.2f", $0.question.difficulty))): \($0.isCorrect ? "correct" : "incorrect")" }
            .joined(separator: "\n")

        let session = LanguageModelSession(instructions: """
            You are a vocabulary assessor scoring an English placement test. \
            You'll be given each quiz word, its difficulty from 0.0 (beginner) to \
            1.0 (advanced), and whether the learner answered correctly. Read the \
            overall pattern — not just the raw count — to estimate the learner's \
            CEFR vocabulary level, then write short, encouraging, specific feedback.
            """)

        do {
            let response = try await session.respond(
                to: "Placement test results:\n\(transcript)",
                generating: QuizAssessment.self
            )
            return QuizResult(
                correctCount: correctCount,
                totalCount: answers.count,
                levelTitle: response.content.levelTitle,
                summary: response.content.summary
            )
        } catch {
            return try await fallback.assessLevel(from: answers)
        }
    }
}

@Generable
private struct QuizAssessment {
    @Guide(description: "The learner's estimated CEFR vocabulary level, formatted like 'Advanced (C1)'")
    let levelTitle: String
    @Guide(description: "Two encouraging sentences of specific feedback about the learner's vocabulary level and where to focus next")
    let summary: String
}
