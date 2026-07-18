import SwiftUI

/// A vocabulary self-assessment screen: headline, subtitle, and a multi-select list
/// of words the user already knows. Continue is always shown, like other
/// multi-select onboarding screens.
struct OnboardingWordChecklistView: View {
    let headline: String
    let subtitle: String
    let words: [String]
    let onContinue: ([String]) -> Void

    @State private var knownWords: Set<String> = []

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text(headline)
                    .font(.system(size: 34, weight: .bold, design: .serif))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.system(size: 17))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(.top, 64)
            .padding(.horizontal, 24)

            VStack(spacing: 14) {
                ForEach(words, id: \.self) { word in
                    wordRow(word)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 40)

            Spacer()

            Button(action: { onContinue(Array(knownWords)) }) {
                Text("Continue")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
            }
            .background(Color(red: 0.576, green: 0.757, blue: 0.757))
            .clipShape(Capsule())
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.169, green: 0.169, blue: 0.169).ignoresSafeArea())
    }

    private func wordRow(_ word: String) -> some View {
        let isKnown = knownWords.contains(word)
        let textColor: Color = isKnown ? .black : .white

        return Button(action: { toggle(word) }) {
            HStack {
                Text(word)
                    .font(.system(size: 19))
                    .foregroundStyle(textColor)
                Spacer()
                Circle()
                    .stroke(textColor, lineWidth: 1.5)
                    .background(Circle().fill(isKnown ? Color.white : .clear))
                    .frame(width: 26, height: 26)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(isKnown ? Color(red: 0.576, green: 0.757, blue: 0.757) : Color(red: 0.251, green: 0.251, blue: 0.251))
            .clipShape(Capsule())
        }
    }

    private func toggle(_ word: String) {
        if knownWords.contains(word) {
            knownWords.remove(word)
        } else {
            knownWords.insert(word)
        }
    }
}

#Preview {
    OnboardingWordChecklistView(
        headline: "Beginner words",
        subtitle: "Select all the ones you know",
        words: ["Borrow", "Metal", "Squint", "Whisper", "Jumble", "Genuine"],
        onContinue: { _ in }
    )
}
