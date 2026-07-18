import SwiftUI

/// Bottom sheet with a word's full dictionary detail — phonetic, every sense's
/// definition, and their example sentences — shown when the reel's info
/// button is tapped.
struct WordInfoSheetView: View {
    let entry: WordEntry
    let selectedAccent: AudioAccent
    let onPlay: () -> Void
    let onSelectAccent: (AudioAccent) -> Void
    let onDismiss: () -> Void

    @Environment(\.readingTheme) private var theme

    private var phonetic: String {
        guard let primarySense = entry.senses.first else { return "" }
        return selectedAccent == .uk ? primarySense.phonBr : primarySense.phonNAm
    }

    private var examples: [String] {
        entry.senses.map(\.example).filter { !$0.isEmpty }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                closeButton
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 18) {
                    Text(entry.word)
                        .font(.system(size: 40, weight: .bold, design: .serif))
                        .foregroundStyle(theme.primaryText)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.5)
                        .lineLimit(2)

                    PhoneticPlayRow(
                        phonetic: phonetic,
                        selectedAccent: selectedAccent,
                        onPlay: onPlay,
                        onSelectAccent: onSelectAccent
                    )

                    VStack(spacing: 10) {
                        ForEach(entry.senses, id: \.self) { sense in
                            Text("(\(PartOfSpeechAbbreviation.abbreviate(sense.partOfSpeech))) \(sense.definition)")
                                .font(.system(size: 19))
                                .foregroundStyle(theme.primaryText)
                                .multilineTextAlignment(.center)
                        }
                    }
                }

                if !examples.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Examples")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(theme.secondaryText)

                        VStack(alignment: .leading, spacing: 14) {
                            ForEach(Array(examples.enumerated()), id: \.offset) { index, example in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("\(index + 1).")
                                        .foregroundStyle(theme.primaryText)
                                    highlightedExample(example)
                                        .foregroundStyle(theme.primaryText)
                                }
                                .font(.system(size: 18))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .background(theme.background)
        .preferredColorScheme(theme.colorScheme)
    }

    private var closeButton: some View {
        Button(action: onDismiss) {
            Image(systemName: "xmark")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(theme.iconTint)
                .frame(width: 36, height: 36)
                .background(theme.chipUnselectedBackground, in: Circle())
        }
    }

    /// Bolds every case-insensitive occurrence of the headword within an
    /// example sentence, matching the reference design.
    private func highlightedExample(_ text: String) -> Text {
        let word = entry.word
        guard !word.isEmpty else { return Text(text) }

        var result = Text("")
        var remainder = Substring(text)
        while let range = remainder.range(of: word, options: .caseInsensitive) {
            result = result + Text(remainder[remainder.startIndex..<range.lowerBound])
            result = result + Text(remainder[range]).fontWeight(.bold)
            remainder = remainder[range.upperBound...]
        }
        return result + Text(remainder)
    }
}
