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

    var body: some View {
        ZStack {
            theme.background
                .ignoresSafeArea()

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
