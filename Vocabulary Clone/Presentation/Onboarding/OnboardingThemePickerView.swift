import SwiftUI

/// Onboarding screen for picking the reading theme. Dark is preselected to match
/// the rest of onboarding, so Continue is enabled immediately. The chosen theme
/// is applied to the reel via `ReadingTheme`.
///
/// Reused from the Profile screen to let the user change their theme later —
/// `initialTheme`/`headline`/`continueButtonTitle` adapt the copy and starting
/// selection, and `onSelect` fires on every tap so callers can apply the theme
/// live instead of waiting for `onContinue`.
struct OnboardingThemePickerView: View {
    var headline: String = "Which theme would\nyou like to start with?"
    var continueButtonTitle: String = "Continue"
    var onSelect: ((ReadingTheme) -> Void)?
    let onContinue: (ReadingTheme) -> Void

    @State private var selectedTheme: ReadingTheme

    init(
        headline: String = "Which theme would\nyou like to start with?",
        continueButtonTitle: String = "Continue",
        initialTheme: ReadingTheme = .dark,
        onSelect: ((ReadingTheme) -> Void)? = nil,
        onContinue: @escaping (ReadingTheme) -> Void
    ) {
        self.headline = headline
        self.continueButtonTitle = continueButtonTitle
        self.onSelect = onSelect
        self.onContinue = onContinue
        _selectedTheme = State(initialValue: initialTheme)
    }

    private let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]

    var body: some View {
        VStack(spacing: 0) {
            Text(headline)
                .font(.system(size: 30, weight: .bold, design: .serif))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .padding(.top, 64)
                .padding(.horizontal, 24)

            LazyVGrid(columns: columns, spacing: 16) {
                themeCard(.dark)
                themeCard(.light)
            }
            .padding(.horizontal, 24)
            .padding(.top, 48)

            Spacer()

            Button(action: { onContinue(selectedTheme) }) {
                Text(continueButtonTitle)
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

    private func themeCard(_ candidate: ReadingTheme) -> some View {
        Button(action: {
            selectedTheme = candidate
            onSelect?(candidate)
        }) {
            ZStack(alignment: .topTrailing) {
                ZStack {
                    candidate.background
                    Text("Aa")
                        .font(.system(size: 28, design: .serif))
                        .foregroundStyle(candidate.primaryText.opacity(candidate == .dark ? 0.8 : 1))
                }
                .aspectRatio(0.69, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1.5)
                )

                if selectedTheme == candidate {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(width: 26, height: 26)
                        .background(Color(red: 0.686, green: 0.839, blue: 0.506))
                        .clipShape(Circle())
                        .padding(8)
                }
            }
        }
    }
}

#Preview {
    OnboardingThemePickerView(onContinue: { _ in })
}
