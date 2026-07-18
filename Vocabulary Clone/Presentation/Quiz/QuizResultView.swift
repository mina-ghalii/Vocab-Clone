import SwiftUI

/// The placement test's final screen: assessed CEFR level, raw score, and the
/// level assessor's short feedback.
struct QuizResultView: View {
    let result: QuizResult
    let onDone: () -> Void

    @Environment(\.readingTheme) private var theme

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundStyle(.teal)

            Text(result.levelTitle)
                .font(.system(size: 30, weight: .bold, design: .serif))
                .multilineTextAlignment(.center)
                .foregroundStyle(theme.primaryText)

            Text("\(result.correctCount) of \(result.totalCount) correct")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(theme.secondaryText)

            Text(result.summary)
                .font(.system(size: 16))
                .multilineTextAlignment(.center)
                .foregroundStyle(theme.secondaryText)
                .padding(.horizontal, 32)
                .padding(.top, 8)

            Spacer()

            Button(action: onDone) {
                Text("Done")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(theme.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
            }
            .background(theme.primaryText, in: Capsule())
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
        }
    }
}

#Preview {
    QuizResultView(
        result: QuizResult(
            correctCount: 7,
            totalCount: 10,
            levelTitle: "Upper Intermediate (B2)",
            summary: "You handled everyday and moderately advanced vocabulary with ease, and stumbled only on the most advanced words. Focus on expanding your C1 vocabulary next."
        ),
        onDone: {}
    )
    .background(ReadingTheme.dark.background)
    .environment(\.readingTheme, .dark)
}
