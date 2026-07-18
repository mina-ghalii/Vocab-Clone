import SwiftUI

/// One card in a `WordListView` list: word + phonetic chip, primary definition
/// and example, the relevant date, and like/save/share actions.
struct WordListRowView: View {
    let entry: WordEntry
    let progress: WordProgress
    let date: Date?
    let selectedAccent: AudioAccent
    let onPlay: () -> Void
    let onShare: () -> Void
    let onLike: () -> Void
    let onSave: () -> Void

    @Environment(\.readingTheme) private var theme

    private var primarySense: Sense? { entry.senses.first }

    private var phonetic: String {
        guard let primarySense else { return "" }
        return selectedAccent == .uk ? primarySense.phonBr : primarySense.phonNAm
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, d MMM yyyy"
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text(entry.word)
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundStyle(theme.primaryText)
                phoneticChip
                Spacer(minLength: 0)
            }

            if let primarySense {
                Text("(\(PartOfSpeechAbbreviation.abbreviate(primarySense.partOfSpeech))) \(primarySense.definition)")
                    .font(.system(size: 16))
                    .foregroundStyle(theme.primaryText)
                Text("(\(primarySense.example))")
                    .font(.system(size: 16))
                    .foregroundStyle(theme.secondaryText)
            }

            HStack {
                if let date {
                    Text(Self.dateFormatter.string(from: date))
                        .font(.system(size: 13))
                        .foregroundStyle(theme.secondaryText)
                }
                Spacer()
                actionIcons
            }
            .padding(.top, 4)
        }
        .padding(18)
        .background(theme.chipUnselectedBackground.opacity(0.6), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var phoneticChip: some View {
        Button(action: onPlay) {
            HStack(spacing: 6) {
                Text(phonetic)
                    .font(.system(size: 14))
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 12))
            }
            .foregroundStyle(theme.secondaryText)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(theme.chipUnselectedBackground, in: Capsule())
        }
    }

    private var actionIcons: some View {
        HStack(spacing: 18) {
            Button(action: onLike) {
                Image(systemName: progress.isLiked ? "heart.fill" : "heart")
                    .foregroundStyle(progress.isLiked ? .red : theme.iconTint)
            }
            Button(action: onSave) {
                Image(systemName: progress.isSaved ? "bookmark.fill" : "bookmark")
                    .foregroundStyle(theme.iconTint)
            }
            Button(action: onShare) {
                Image(systemName: "square.and.arrow.up")
                    .foregroundStyle(theme.iconTint)
            }
        }
        .font(.system(size: 18))
    }
}
