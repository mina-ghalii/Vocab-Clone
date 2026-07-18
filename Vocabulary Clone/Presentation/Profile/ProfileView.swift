import SwiftUI
import SwiftData

/// The screen shown when the reel's profile icon is tapped: a close button,
/// a "take a test" row, and cards for the three word lists (Favorites, Your
/// words, History). Tapping a card swaps in a `WordListView` in place.
struct ProfileView: View {
    let repository: WordHistoryQuerying & WordStateMutating
    let audioPlayer: AudioPlayerProtocol
    let shareImageGenerator: ShareImageGenerating
    let preferredAccent: AudioAccent
    var onWordsReseeded: () -> Void = {}

    @State private var presentedKind: WordListKind?
    @State private var isTestPresented = false
    @State private var isChangingTheme = false
    @AppStorage("readingTheme") private var readingThemeRawValue = ReadingTheme.dark.rawValue
    @Environment(\.readingTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            if let presentedKind {
                WordListView(
                    kind: presentedKind,
                    repository: repository,
                    audioPlayer: audioPlayer,
                    shareImageGenerator: shareImageGenerator,
                    preferredAccent: preferredAccent,
                    onBack: { self.presentedKind = nil }
                )
            } else if isChangingTheme {
                OnboardingThemePickerView(
                    headline: "Choose your\nreading theme",
                    continueButtonTitle: "Done",
                    initialTheme: theme,
                    onSelect: { readingThemeRawValue = $0.rawValue },
                    onContinue: { _ in isChangingTheme = false }
                )
            } else {
                menu
            }
        }
        .preferredColorScheme(theme.colorScheme)
        .fullScreenCover(isPresented: $isTestPresented) {
            QuizView(
                viewModel: QuizViewModel(
                    reseeder: SwiftDataWordReseeder(
                        modelContext: modelContext,
                        profile: OnboardingProfile.load() ?? OnboardingProfile()
                    ),
                    onReseedCompleted: onWordsReseeded
                ),
                onClose: { isTestPresented = false }
            )
            .environment(\.readingTheme, theme)
        }
    }

    private var menu: some View {
        VStack(alignment: .leading, spacing: 28) {
            closeButton

            Text("Profile")
                .font(.system(size: 34, weight: .bold, design: .serif))
                .foregroundStyle(theme.primaryText)

            takeTestRow

            changeThemeRow

            vocabularyGrid

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(theme.iconTint)
                .frame(width: 44, height: 44)
                .background(theme.chipUnselectedBackground, in: Circle())
        }
    }

    private var takeTestRow: some View {
        Button {
            isTestPresented = true
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(theme.iconTint)
                    .frame(width: 44, height: 44)
                    .background(theme.chipUnselectedBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                Text("Take a test to know your level")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(theme.primaryText)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(theme.secondaryText)
            }
            .padding(16)
            .background(theme.chipUnselectedBackground.opacity(0.6), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    private var changeThemeRow: some View {
        Button {
            isChangingTheme = true
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "circle.lefthalf.filled")
                    .font(.system(size: 20))
                    .foregroundStyle(theme.iconTint)
                    .frame(width: 44, height: 44)
                    .background(theme.chipUnselectedBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                Text("Change reading theme")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(theme.primaryText)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(theme.secondaryText)
            }
            .padding(16)
            .background(theme.chipUnselectedBackground.opacity(0.6), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    private var vocabularyGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Vocabulary")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(theme.primaryText)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                vocabularyCard(kind: .favorites, systemImage: "heart.fill")
                vocabularyCard(kind: .savedWords, systemImage: "bookmark.fill")
                vocabularyCard(kind: .history, systemImage: "clock.fill")
            }
        }
    }

    private func vocabularyCard(kind: WordListKind, systemImage: String) -> some View {
        Button {
            presentedKind = kind
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 26))
                    .foregroundStyle(theme.iconTint)

                Spacer(minLength: 0)

                Text(kind.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(theme.primaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .frame(height: 140)
            .background(theme.chipUnselectedBackground.opacity(0.6), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }
}
