import SwiftUI

/// Walks the user through the onboarding screens in order, then calls `onFinished`.
struct OnboardingFlowView: View {
    private enum Step {
        case welcome
        case referralSource
        case age
        case gender
        case name
        case customizeIntro
        case themePicker
        case voicePicker
        case goalsIntro
        case topics
        case curiosity
        case vocabularyLevel
        case encounterFrequency
        case vocabularySelfDescription
        case weakestArea
        case beginnerWords
        case intermediateWords
        case advancedWords
    }

    let audioPlayer: AudioPlayerProtocol
    let onFinished: (OnboardingProfile, ReadingTheme, AudioAccent) -> Void

    @State private var step: Step = .welcome
    @State private var selectedTheme: ReadingTheme = .dark
    @State private var selectedAccent: AudioAccent = .uk
    @State private var profile = OnboardingProfile()
    @State private var placementWords = (try? PlacementWordsLoader().load()) ?? []

    var body: some View {
        switch step {
        case .welcome:
            OnboardingWelcomeView(onGetStarted: { step = .referralSource })
        case .referralSource:
            OnboardingChoiceView(
                headline: "How did you hear\nabout Vocabulary?",
                options: ["TikTok", "Web search", "Instagram", "Friend/family", "App Store", "Facebook", "Other"],
                onSelect: { selection in
                    profile.referralSource = selection.first
                    step = .age
                }
            )
        case .age:
            OnboardingChoiceView(
                headline: "How old are you?",
                options: ["13 to 17", "18 to 24", "25 to 34", "35 to 44", "45 to 54", "55+"],
                showsSkip: true,
                onSelect: { selection in
                    profile.ageRange = selection.first
                    step = .gender
                },
                onSkip: { step = .gender }
            )
        case .gender:
            OnboardingChoiceView(
                headline: "Which option represents\nyou best?",
                options: ["Female", "Male", "Other", "Prefer not to say"],
                showsSkip: true,
                onSelect: { selection in
                    profile.gender = selection.first
                    step = .name
                },
                onSkip: { step = .name }
            )
        case .name:
            OnboardingNameInputView(
                onContinue: { name in
                    profile.name = name
                    step = .customizeIntro
                },
                onSkip: { step = .customizeIntro }
            )
        case .customizeIntro:
            OnboardingIllustrationView(
                illustrationAssetName: "OnboardingCustomizeIllustration",
                headline: "Customize the app to\nimprove your experience",
                onContinue: { step = .themePicker }
            )
        case .themePicker:
            OnboardingThemePickerView(onContinue: { theme in
                selectedTheme = theme
                step = .voicePicker
            })
        case .voicePicker:
            OnboardingVoicePickerView(
                audioPlayer: audioPlayer,
                onContinue: { accent in
                    selectedAccent = accent
                    step = .goalsIntro
                }
            )
        case .goalsIntro:
            OnboardingIllustrationView(
                illustrationAssetName: "OnboardingGoalsIllustration",
                headline: "Set up Vocabulary to help\nyou achieve your goals",
                onContinue: { step = .topics }
            )
        case .topics:
            OnboardingChoiceView(
                headline: "Which topics are you\ninterested in?",
                options: [
                    "Society", "Emotions", "Words in foreign languages", "Human body", "Business",
                    "Nature", "Science & technology", "Arts & entertainment", "Travel", "Other",
                ],
                showsSkip: true,
                allowsMultipleSelection: true,
                onSelect: { selection in
                    profile.topics = Set(selection)
                    step = .curiosity
                },
                onSkip: { step = .curiosity }
            )
        case .curiosity:
            OnboardingChoiceView(
                headline: "What drives\nyour curiosity?",
                options: ["Impressing other people", "I'm a lifelong learner", "Knowing more than others", "Breaking out of my bubble", "Other"],
                showsSkip: true,
                allowsMultipleSelection: true,
                onSelect: { selection in
                    profile.curiosityMotivations = Set(selection)
                    step = .vocabularyLevel
                },
                onSkip: { step = .vocabularyLevel }
            )
        case .vocabularyLevel:
            OnboardingChoiceView(
                headline: "What's your\nvocabulary level?",
                options: ["Beginner", "Intermediate", "Advanced"],
                showsSkip: true,
                onSelect: { selection in
                    profile.vocabularyLevel = selection.first
                    step = .encounterFrequency
                },
                onSkip: { step = .encounterFrequency }
            )
        case .encounterFrequency:
            OnboardingChoiceView(
                headline: "Do you often encounter\nwords you don't know?",
                options: ["Daily", "A few times a week", "Rarely", "Never"],
                showsSkip: true,
                onSelect: { selection in
                    profile.encounterFrequency = selection.first
                    step = .vocabularySelfDescription
                },
                onSkip: { step = .vocabularySelfDescription }
            )
        case .vocabularySelfDescription:
            OnboardingChoiceView(
                headline: "How would you describe\nyour vocabulary?",
                options: ["Struggle to find the right words", "Get by but want to improve", "Comfortable in most situations", "Very articulate"],
                showsSkip: true,
                onSelect: { selection in
                    profile.vocabularySelfDescription = selection.first
                    step = .weakestArea
                },
                onSkip: { step = .weakestArea }
            )
        case .weakestArea:
            OnboardingChoiceView(
                headline: "Where does your\nvocabulary feel weakest?",
                options: ["In social conversations", "I always feel confident", "At work", "When writing", "In school", "When reading"],
                showsSkip: true,
                allowsMultipleSelection: true,
                onSelect: { selection in
                    profile.weakestAreas = Set(selection)
                    step = .beginnerWords
                },
                onSkip: { step = .beginnerWords }
            )
        case .beginnerWords:
            OnboardingWordChecklistView(
                headline: "Beginner words",
                subtitle: "Select all the ones you know",
                words: placementWords.beginnerScreenWords.map(\.word),
                onContinue: { known in
                    profile.knownPlacementWords.formUnion(known)
                    step = .intermediateWords
                }
            )
        case .intermediateWords:
            OnboardingWordChecklistView(
                headline: "Intermediate words",
                subtitle: "Select all the ones you know",
                words: placementWords.intermediateScreenWords.map(\.word),
                onContinue: { known in
                    profile.knownPlacementWords.formUnion(known)
                    step = .advancedWords
                }
            )
        case .advancedWords:
            OnboardingWordChecklistView(
                headline: "Advanced words",
                subtitle: "Select all the ones you know",
                words: placementWords.advancedScreenWords.map(\.word),
                onContinue: { known in
                    profile.knownPlacementWords.formUnion(known)
                    onFinished(profile, selectedTheme, selectedAccent)
                }
            )
        }
    }
}
