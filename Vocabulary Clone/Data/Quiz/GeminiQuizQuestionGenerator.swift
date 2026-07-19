import Foundation

/// Writes fresh placement-test questions for a set of real, ground-truth
/// words using the Gemini API. Replaces the on-device Apple Intelligence
/// path, which proved unreliable in testing — the on-device model catalog
/// was missing assets on-device and every request failed regardless of how
/// the request was shaped. A cloud model has no on-device asset-provisioning
/// failure mode, and Gemini's structured-output schema handles arrays and
/// integers natively, so this asks for the whole word set in a single call.
/// Falls back to `StaticQuizQuestionGenerator` when the network call fails
/// (no connectivity, bad key, rate limit) or its output fails validation.
struct GeminiQuizQuestionGenerator: QuizQuestionGenerating {
    private let client: GeminiClient
    private let fallback: QuizQuestionGenerating = StaticQuizQuestionGenerator()

    init(apiKey: String = Secrets.geminiAPIKey) {
        client = GeminiClient(apiKey: apiKey)
    }

    func generateQuestions(from candidates: [QuizWordCandidate]) async throws -> [QuizQuestion] {
        guard !candidates.isEmpty else {
            return try await fallback.generateQuestions(from: candidates)
        }

        do {
            return try await generate(for: candidates)
        } catch {
            #if DEBUG
            print("[QuizQuestionGenerator] Gemini generation failed, falling back to static bank — \(error)")
            #endif
            return try await fallback.generateQuestions(from: candidates)
        }
    }

    private func generate(for candidates: [QuizWordCandidate]) async throws -> [QuizQuestion] {
        let types = QuizQuestionType.rotation(count: candidates.count)
        let manifest = zip(candidates, types)
            .map { candidate, type in
                "- word: \"\(candidate.word)\", type: \(type.rawValue), definition: \"\(candidate.definition)\""
            }
            .joined(separator: "\n")

        let generated: GeneratedQuizQuestionSet = try await client.generate(
            systemInstruction: Self.instructions,
            prompt: "Generate one question per word, in the same order, for:\n\(manifest)",
            responseSchema: Self.responseSchema,
            as: GeneratedQuizQuestionSet.self
        )

        guard generated.questions.count == candidates.count else { throw GenerationError.countMismatch }

        return try zip(zip(candidates, types), generated.questions).map { pair, generatedQuestion in
            let (candidate, type) = pair
            guard generatedQuestion.word.caseInsensitiveCompare(candidate.word) == .orderedSame else {
                throw GenerationError.wordMismatch
            }
            guard generatedQuestion.options.count >= 2,
                  generatedQuestion.options.indices.contains(generatedQuestion.correctOptionIndex)
            else {
                throw GenerationError.badOptionIndex
            }
            if type == .fillInTheGap {
                guard generatedQuestion.promptSentence.contains("{blank}"),
                      generatedQuestion.options[generatedQuestion.correctOptionIndex] == candidate.word
                else {
                    throw GenerationError.malformedFillInTheGap
                }
            }

            // Gemini reliably writes the correct option first and reports
            // correctOptionIndex: 0 regardless of prompt wording, so its
            // reported position can't be trusted as already-random — shuffle
            // here and recompute the index instead of relying on the model
            // to vary it.
            var labeledOptions = generatedQuestion.options.enumerated().map { index, text in
                (text: text, isCorrect: index == generatedQuestion.correctOptionIndex)
            }
            labeledOptions.shuffle()
            guard let correctIndex = labeledOptions.firstIndex(where: \.isCorrect) else {
                throw GenerationError.badOptionIndex
            }

            return QuizQuestion(
                id: candidate.word,
                type: type,
                word: candidate.word,
                promptSentence: type == .fillInTheGap ? generatedQuestion.promptSentence : nil,
                options: labeledOptions.map(\.text),
                correctOptionIndex: correctIndex,
                difficulty: candidate.difficulty
            )
        }
    }

    private static let instructions = """
        You write multiple-choice placement-test questions for an English \
        vocabulary app. For each word given you're provided its exact \
        dictionary definition and a required question type. Treat the \
        definition as the single source of truth for correctness — never \
        invent a different meaning for the word.

        Question types:
        - meaningMatch: show the word alone (promptSentence must be an empty \
          string); write three short definition-style options, one matching \
          the given definition and two plausible-but-wrong definitions of \
          similar length and tone.
        - fillInTheGap: write one original sentence that uses the word \
          naturally, then replace that exact word with the literal token \
          {blank}; the three options must be single words, and the option \
          equal to the target word must be the correct one.
        - matchSynonyms: show the word alone (promptSentence must be an empty \
          string); three single-word options, one a true synonym of the word \
          given its definition, two that are clearly not synonyms.

        Keep wrong options plausible, not silly, so the question genuinely \
        tests vocabulary knowledge. Return exactly one question per word \
        listed, in the same order given.
        """

    private static let responseSchema: GeminiSchema = {
        let question = GeminiSchema(
            type: "OBJECT",
            properties: [
                "word": GeminiSchema(type: "STRING"),
                "options": GeminiSchema(type: "ARRAY", items: GeminiSchema(type: "STRING")),
                "correctOptionIndex": GeminiSchema(type: "INTEGER"),
                "promptSentence": GeminiSchema(type: "STRING"),
            ],
            required: ["word", "options", "correctOptionIndex", "promptSentence"]
        )
        return GeminiSchema(
            type: "OBJECT",
            properties: ["questions": GeminiSchema(type: "ARRAY", items: question)],
            required: ["questions"]
        )
    }()

    private enum GenerationError: Error {
        case countMismatch
        case wordMismatch
        case badOptionIndex
        case malformedFillInTheGap
    }
}

private struct GeneratedQuizQuestion: Decodable {
    let word: String
    let options: [String]
    let correctOptionIndex: Int
    let promptSentence: String
}

private struct GeneratedQuizQuestionSet: Decodable {
    let questions: [GeneratedQuizQuestion]
}
