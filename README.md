# Vocab Clone

A reel-style, offline-first English vocabulary app (Oxford 5000) that personalizes which words it shows based on the user's CEFR level.

## Demo

[Screen Recording 2026-07-19 at 4.24.41 PM.mp4](./[Screen%20Recording%202026-07-19%20at%204.24.41%E2%80%AFPM.mp4](https://github.com/mina-ghalii/Vocab-Clone/blob/main/Screen%20Recording%202026-07-19%20at%204.24.41%E2%80%AFPM.mp4))

## How it was built

1. **Dataset** — needed to work fully offline with CEFR ratings (to grade word difficulty) and real pronunciation audio. Used [Oxford 5000 vocabulary + audio + definitions](https://github.com/winterdl/oxford-5000-vocabulary-audio-definition), bundled as [oxford_5000.json](Vocabulary%20Clone/Resources/oxford_5000.json) + [Audio/uk](Vocabulary%20Clone/Resources/Audio/uk) / [Audio/us](Vocabulary%20Clone/Resources/Audio/us).

2. **Level inference (Gemini)** — onboarding's placement checklist (known/unknown real words across A1–C1) is scored by Gemini instead of a fixed rule: [GeminiClient.swift](Vocabulary%20Clone/Data/Gemini/GeminiClient.swift) (shared API client) → [GeminiLevelInferenceGenerator.swift](Vocabulary%20Clone/Data/Personalization/GeminiLevelInferenceGenerator.swift) (builds prompt, returns CEFR level) → [PersonalizationSignalsResolver.swift](Vocabulary%20Clone/Data/Personalization/PersonalizationSignalsResolver.swift) (falls back to a deterministic mapper if the call fails). Both Gemini generators sit behind Domain-layer interfaces — [LevelInferring](Vocabulary%20Clone/Domain/Protocols/LevelInferring.swift) (onboarding) and [VocabularyLevelAssessing](Vocabulary%20Clone/Domain/Protocols/VocabularyLevelAssessing.swift) (quiz) — so the LLM provider is swappable: callers depend on the protocol, not on `GeminiLevelInferenceGenerator`/`GeminiLevelAssessor` directly, and `HeuristicLevelAssessor` already proves a second, non-LLM implementation drops in with zero changes elsewhere.

3. **Seeding into SwiftData** — parsing/scoring 5000 words on every launch would be wasteful, and per-word state (seen/liked/saved) needs to persist. Used **SwiftData** (Apple's latest persistence framework):
   - [WordEntry.swift](Vocabulary%20Clone/Domain/Models/WordEntry.swift) — one row per word, seeded once, read-only after.
   - [WordProgress.swift](Vocabulary%20Clone/Domain/Models/WordProgress.swift) — separate mutable per-user state, so re-seeding never wipes likes/saves.
   - [DataSeedingService.swift](Vocabulary%20Clone/Data/Seeding/DataSeedingService.swift) — inserts everything once on first launch; a no-op on every launch after.
   - [SwiftDataWordRepository.swift](Vocabulary%20Clone/Data/Persistence/SwiftDataWordRepository.swift) — the only class that touches `ModelContext` directly.

   **Logic, briefly:** [JSONWordSeedSource.swift](Vocabulary%20Clone/Data/Seeding/JSONWordSeedSource.swift) groups the JSON into words, [PersonalizedWordOrderer.swift](Vocabulary%20Clone/Domain/Personalization/PersonalizedWordOrderer.swift) ranks them (known words dropped → at-or-above-level words first → preferred topics floated to the front → shuffled), and that order becomes `sortIndex` at insert time via [PersonalizedWordSeedSource.swift](Vocabulary%20Clone/Data/Seeding/PersonalizedWordSeedSource.swift). **UX effect:** a brief one-time setup pass on first launch only; every launch after opens straight into a reel already sorted for that user.

4. **Retest → reseed** — taking the in-app quiz re-assesses the user via [GeminiLevelAssessor.swift](Vocabulary%20Clone/Data/Quiz/GeminiLevelAssessor.swift) (CEFR band computed deterministically from answers; Gemini only writes the feedback text). [SwiftDataWordReseeder.swift](Vocabulary%20Clone/Data/Seeding/SwiftDataWordReseeder.swift) then re-runs the same ordering against the already-seeded rows and resets scroll position to the top. **UX effect:** finishing the quiz feels like the reel refreshing, now biased to the user's newly measured level.

## New features

- **Pronounce-along mic** — press-and-hold mic ([MicButtonView.swift](Vocabulary%20Clone/Presentation/Reel/MicButtonView.swift)) checks your pronunciation via on-device speech recognition ([AppleSpeechRecognitionService.swift](Vocabulary%20Clone/Data/Speech/AppleSpeechRecognitionService.swift)) — nothing leaves the device.
- **US/UK accent toggle** — switch playback accent in the reel to hear both pronunciations ([ReelViewModel.swift](Vocabulary%20Clone/Presentation/Reel/ReelViewModel.swift), [AudioAccent.swift](Vocabulary%20Clone/Domain/Models/AudioAccent.swift)).

## Animation

- **Tutorial** — spring-animated coach-mark walkthrough spotlighting each control in sequence ([ReelTutorialOverlay.swift](Vocabulary%20Clone/Presentation/Reel/Tutorial/ReelTutorialOverlay.swift)).

## Haptics

- **Mic press** — impact feedback on press, success/error notification feedback on result ([MicButtonView.swift](Vocabulary%20Clone/Presentation/Reel/MicButtonView.swift)).

## Task 2

**Feature currently spoiling the UX — onboarding has too many screens.** [OnboardingFlowView.swift](Vocabulary%20Clone/Presentation/Onboarding/OnboardingFlowView.swift) walks the user through **18 sequential steps** (welcome → referral source → age → gender → name → customize intro → theme → voice → goals intro → topics → curiosity → vocabulary level → encounter frequency → self-description → weakest area → beginner/intermediate/advanced placement words) before they ever see a word.

**Missing feature — pronunciation practice.** Implemented as the mic feature described above under [New features](#new-features): press-and-hold recording, on-device speech recognition, and haptic feedback on press/result ([MicButtonView.swift](Vocabulary%20Clone/Presentation/Reel/MicButtonView.swift), [AppleSpeechRecognitionService.swift](Vocabulary%20Clone/Data/Speech/AppleSpeechRecognitionService.swift)).

## Setup

1. Copy [Secrets.swift.template](Vocabulary%20Clone/Secrets.swift.template) to `Vocabulary Clone/Secrets.swift` (gitignored) and add a Gemini API key.
2. Open `Vocabulary Clone.xcodeproj` in Xcode and run.

Without a key, the app still works via its deterministic on-device fallbacks.
