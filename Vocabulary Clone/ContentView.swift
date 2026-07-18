//
//  ContentView.swift
//  Vocabulary Clone
//
//  Created by Mina Ghali on 14/07/2026.
//

import SwiftUI
import SwiftData

/// New users see onboarding immediately (it needs no store access), then the word
/// bank is seeded in personalized order once onboarding answers are in hand.
/// Returning users seed on launch as before — `DataSeedingService` finds existing
/// rows and returns near-instantly, so the source passed there doesn't matter.
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("readingTheme") private var readingThemeRawValue = ReadingTheme.dark.rawValue
    @AppStorage("preferredAccent") private var preferredAccentRawValue = AudioAccent.uk.rawValue

    @State private var isSeeding = true
    @State private var isPersonalizing = false
    @State private var seedingError: String?
    @State private var audioPlayer = LocalAudioPlayerService()
    @State private var justFinishedOnboarding = false

    private var readingTheme: ReadingTheme {
        ReadingTheme(rawValue: readingThemeRawValue) ?? .dark
    }

    private var preferredAccent: AudioAccent {
        AudioAccent(rawValue: preferredAccentRawValue) ?? .uk
    }

    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                if isPersonalizing {
                    loadingView(message: "Personalizing your words…")
                } else {
                    OnboardingFlowView(
                        audioPlayer: audioPlayer,
                        onFinished: { profile, theme, accent in
                            readingThemeRawValue = theme.rawValue
                            preferredAccentRawValue = accent.rawValue
                            profile.save()
                            Task { await personalizeAndSeed(profile: profile) }
                        }
                    )
                }
            } else if isSeeding {
                loadingView(message: "Loading words…")
            } else if let seedingError {
                Text(seedingError)
                    .foregroundStyle(.red)
                    .padding()
            } else {
                ReelView(
                    viewModel: ReelViewModel(
                        repository: SwiftDataWordRepository(modelContext: modelContext),
                        audioPlayer: audioPlayer,
                        shareImageGenerator: WordCardImageGenerator(),
                        preferredAccent: preferredAccent
                    ),
                    showsWelcomeCard: justFinishedOnboarding
                )
                .environment(\.readingTheme, readingTheme)
            }
        }
        .task {
            guard hasCompletedOnboarding else { return }
            await seed(using: JSONWordSeedSource())
        }
    }

    private func loadingView(message: String) -> some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ProgressView(message)
                .tint(.white)
                .foregroundStyle(.white)
        }
    }

    /// Resolves the user's reading level (on-device AI, falling back to the
    /// deterministic mapper), seeds the store in that order, then reveals the reel.
    private func personalizeAndSeed(profile: OnboardingProfile) async {
        isPersonalizing = true
        let placementWords = (try? PlacementWordsLoader().load()) ?? []
        let signals = await PersonalizationSignalsResolver.resolve(for: profile, placementWords: placementWords)
        await seed(using: PersonalizedWordSeedSource(profile: profile, signals: signals, placementWords: placementWords))
        justFinishedOnboarding = true
        hasCompletedOnboarding = true
        isPersonalizing = false
    }

    private func seed(using seedProvider: WordSeedProviding) async {
        isSeeding = true
        let seedingService = DataSeedingService(
            modelContext: modelContext,
            seedProvider: seedProvider
        )
        do {
            try await seedingService.seedIfNeeded()
        } catch {
            seedingError = error.localizedDescription
        }
        isSeeding = false
    }
}

//#Preview {
//    ContentView()
//}
