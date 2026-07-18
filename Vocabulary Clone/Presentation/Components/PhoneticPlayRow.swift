import SwiftUI

/// IPA transcription + play button + inline US/UK accent toggle, shown once
/// per card next to the primary (first) sense's phonetics.
struct PhoneticPlayRow: View {
    let phonetic: String
    let selectedAccent: AudioAccent
    let onPlay: () -> Void
    let onSelectAccent: (AudioAccent) -> Void

    @Environment(\.readingTheme) private var theme

    var body: some View {
        HStack(spacing: 10) {
            AccentToggle(title: "UK", isSelected: selectedAccent == .uk) {
                onSelectAccent(.uk)
            }

            Text(phonetic)
                .font(.system(size: 17))
                .foregroundStyle(theme.secondaryText)

            Button(action: onPlay) {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 17))
                    .foregroundStyle(theme.iconTint)
            }
            .tutorialAnchor(.speaker)

            AccentToggle(title: "US", isSelected: selectedAccent == .us) {
                onSelectAccent(.us)
            }
        }
    }
}

private struct AccentToggle: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.readingTheme) private var theme

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(isSelected ? theme.chipSelectedText : theme.chipUnselectedText)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isSelected ? theme.chipSelectedBackground : theme.chipUnselectedBackground)
                .clipShape(Capsule())
        }
    }
}
