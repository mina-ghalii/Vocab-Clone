import SwiftUI

/// Full-screen placement test: a progress bar, one question at a time in a
/// card-stack, and three answer options that turn green/red once tapped. A
/// tapped answer auto-advances to the next question (see `QuizViewModel`);
/// the last question hands off to `QuizResultView` once the level assessor finishes.
struct QuizView: View {
    @State private var viewModel: QuizViewModel
    let onClose: () -> Void

    @Environment(\.readingTheme) private var theme

    init(viewModel: QuizViewModel = QuizViewModel(), onClose: @escaping () -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onClose = onClose
    }

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            if let result = viewModel.result {
                QuizResultView(result: result, onDone: onClose)
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
            } else {
                quizContent
            }
        }
        .animation(.easeInOut(duration: 0.4), value: viewModel.result != nil)
        .preferredColorScheme(theme.colorScheme)
    }

    private var quizContent: some View {
        VStack(spacing: 0) {
            header

            Spacer(minLength: 24)

            questionCard
                .id(viewModel.currentIndex)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

            Spacer(minLength: 32)

            options
                .id(viewModel.currentIndex)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .animation(.spring(duration: 0.4), value: viewModel.currentIndex)
        .overlay {
            if viewModel.isAssessing {
                ProgressView()
                    .tint(theme.primaryText)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(theme.iconTint)
                    .frame(width: 44, height: 44)
                    .background(theme.chipUnselectedBackground, in: Circle())
            }

            ProgressView(value: viewModel.progress)
                .tint(.teal)
                .animation(.easeInOut(duration: 0.3), value: viewModel.progress)
        }
    }

    private var typeChip: some View {
        Text(viewModel.currentQuestion.type.label)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(theme.chipUnselectedText)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(theme.chipUnselectedBackground, in: Capsule())
    }

    private var questionCard: some View {
        VStack(spacing: 20) {
            typeChip

            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(theme.chipUnselectedBackground)
                    .frame(height: 220)
                    .rotationEffect(.degrees(-3))
                    .offset(y: 6)

                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(theme.chipUnselectedBackground.opacity(0.85))
                    .frame(height: 220)

                cardContent
                    .padding(24)
            }
        }
    }

    @ViewBuilder
    private var cardContent: some View {
        let question = viewModel.currentQuestion
        if let sentence = question.promptSentence {
            Text(filledSentence(sentence))
                .font(.system(size: 22, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(theme.primaryText)
        } else {
            Text(question.word)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(theme.primaryText)
        }
    }

    /// Renders `{blank}` as an underline until answered, then swaps in the
    /// picked option, bolded and underlined like the finished screenshot.
    private func filledSentence(_ sentence: String) -> AttributedString {
        let filler = viewModel.selectedOptionIndex.map { viewModel.currentQuestion.options[$0] } ?? "_____"
        var attributed = AttributedString(sentence.replacingOccurrences(of: "{blank}", with: filler))
        if let range = attributed.range(of: filler) {
            attributed[range].font = .system(size: 22, weight: .bold)
            attributed[range].underlineStyle = .single
        }
        return attributed
    }

    private var options: some View {
        VStack(spacing: 14) {
            ForEach(Array(viewModel.currentQuestion.options.enumerated()), id: \.offset) { index, option in
                optionButton(index: index, text: option)
            }
        }
    }

    private func optionButton(index: Int, text: String) -> some View {
        Button {
            withAnimation(.spring(duration: 0.3)) {
                viewModel.selectAnswer(index)
            }
        } label: {
            HStack {
                Text(text)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(theme.primaryText)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 8)

                feedbackIcon(for: index)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(optionBackground(for: index), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .disabled(viewModel.selectedOptionIndex != nil)
    }

    @ViewBuilder
    private func feedbackIcon(for index: Int) -> some View {
        if let selected = viewModel.selectedOptionIndex {
            let question = viewModel.currentQuestion
            if index == question.correctOptionIndex {
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            } else if index == selected {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
    }

    private func optionBackground(for index: Int) -> Color {
        guard let selected = viewModel.selectedOptionIndex else {
            return theme.chipUnselectedBackground.opacity(0.6)
        }
        let question = viewModel.currentQuestion
        if index == question.correctOptionIndex {
            return Color.green.opacity(0.55)
        }
        if index == selected {
            return Color.red.opacity(0.55)
        }
        return theme.chipUnselectedBackground.opacity(0.6)
    }
}

#Preview {
    QuizView(onClose: {})
        .environment(\.readingTheme, .dark)
}
