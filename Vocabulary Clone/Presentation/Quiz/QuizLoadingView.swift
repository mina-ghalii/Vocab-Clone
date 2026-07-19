import SwiftUI

/// Shown while `QuizViewModel.generateQuestions()` is in flight, before the
/// quiz screen reveals any question — so the test never flashes the static
/// bank and then swaps to a generated set mid-glance. Reuses the `sparkles`
/// mark `QuizResultView` uses for AI-produced content, pulsing gently, with
/// status text that rotates so the wait reads as progress rather than a
/// stall — real placement-test generation is a single network round trip
/// with no sub-steps to report honestly, so the messages are paced by time
/// rather than bound to actual stages.
struct QuizLoadingView: View {
    @Environment(\.readingTheme) private var theme
    @State private var messageIndex = 0

    private let messages = [
        "Picking real words for you…",
        "Writing your questions…",
        "Almost ready…",
    ]

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundStyle(.teal)
                .symbolEffect(.pulse, options: .repeating, isActive: true)

            Text(messages[messageIndex])
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(theme.secondaryText)
                .id(messageIndex)
                .transition(.opacity)
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1.6))
                guard !Task.isCancelled else { return }
                withAnimation(.easeInOut(duration: 0.3)) {
                    messageIndex = (messageIndex + 1) % messages.count
                }
            }
        }
    }
}

#Preview {
    QuizLoadingView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ReadingTheme.dark.background)
        .environment(\.readingTheme, .dark)
}
