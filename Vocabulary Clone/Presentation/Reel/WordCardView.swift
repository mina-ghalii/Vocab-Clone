import SwiftUI

/// One full-screen reel card: word, phonetic + play row, stacked sense
/// definitions, and the bottom action rail — matching the reference screenshot.
struct WordCardView: View {
    let entry: WordEntry
    var viewModel: ReelViewModel

    @Environment(\.readingTheme) private var theme

    private var primarySense: Sense? { entry.senses.first }

    private var phonetic: String {
        guard let primarySense else { return "" }
        return viewModel.selectedAccent == .uk ? primarySense.phonBr : primarySense.phonNAm
    }

    #if DEBUG
    private static let debugTags: [String: WordTags] = (try? WordTagsLoader().load()) ?? [:]

    private var debugLevelAndTags: String {
        let level = entry.cefrLevel?.rawValue.uppercased() ?? "?"
        let tags = Self.debugTags[entry.word]?.topics.joined(separator: ", ")
        return "\(level) · \(tags?.isEmpty == false ? tags! : "no tags")"
    }

    private var debugUserLevel: String {
        "Self-reported: \(OnboardingProfile.load()?.vocabularyLevel ?? "unset")"
    }

    private var debugInferredLevel: String {
        guard let (signals, source) = PersonalizationSignals.loadForDebugging() else {
            return "Inferred: none saved"
        }
        return "Inferred: \(signals.targetLevel.rawValue.uppercased()) (\(source))"
    }
    #endif

    var body: some View {
        ZStack {
            theme.background
                .ignoresSafeArea()

            #if DEBUG
            VStack {
                HStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(debugLevelAndTags)
                        Text(debugUserLevel)
                        Text(debugInferredLevel)
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.yellow.opacity(0.9), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                Spacer()
            }
            .zIndex(1)
            #endif

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 18) {
                    Text(entry.word)
                        .font(.system(size: 44, weight: .bold, design: .serif))
                        .foregroundStyle(theme.primaryText)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.5)
                        .lineLimit(2)

                    PhoneticPlayRow(
                        phonetic: phonetic,
                        selectedAccent: viewModel.selectedAccent,
                        onPlay: { viewModel.playCurrentAudio(for: entry) },
                        onSelectAccent: { viewModel.selectAccent($0) }
                    )

                    VStack(spacing: 10) {
                        ForEach(entry.senses, id: \.self) { sense in
                            Text("(\(PartOfSpeechAbbreviation.abbreviate(sense.partOfSpeech))) \(sense.definition)")
                                .font(.system(size: 19))
                                .foregroundStyle(theme.primaryText)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, 32)
                }

                MicButtonView(
                    state: viewModel.pronunciationState,
                    onPress: { Task { await viewModel.beginPronunciationCheck(for: entry) } },
                    onRelease: { Task { await viewModel.endPronunciationCheck(for: entry) } }
                )
                .padding(.top, 40)

                Spacer()
                Spacer()

                ActionRailView(
                    isLiked: viewModel.progressByEntryId[entry.id]?.isLiked ?? false,
                    isSaved: viewModel.progressByEntryId[entry.id]?.isSaved ?? false,
                    onInfo: { viewModel.infoTapped(for: entry) },
                    onShare: { viewModel.shareCurrentCard(entry) },
                    onLike: { Task { await viewModel.toggleLike(entry) } },
                    onSave: { Task { await viewModel.toggleSave(entry) } }
                )
                .padding(.bottom, 48)
            }
        }
    }
}
