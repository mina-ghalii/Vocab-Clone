import SwiftUI

/// The four-icon action rail: info / share / like / save. Purely presentational —
/// state and behavior are owned by the caller.
struct ActionRailView: View {
    let isLiked: Bool
    let isSaved: Bool
    let onInfo: () -> Void
    let onShare: () -> Void
    let onLike: () -> Void
    let onSave: () -> Void

    @Environment(\.readingTheme) private var theme

    var body: some View {
        HStack {
            Spacer()
            button("info.circle", action: onInfo)
            Spacer()
            button("square.and.arrow.up", action: onShare)
            Spacer()
            button(isLiked ? "heart.fill" : "heart", tint: isLiked ? .red : theme.iconTint, action: onLike)
            Spacer()
            button(isSaved ? "bookmark.fill" : "bookmark", action: onSave)
            Spacer()
        }
    }

    private func button(_ systemImage: String, tint: Color? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 22))
                .foregroundStyle(tint ?? theme.iconTint)
                .frame(width: 44, height: 44)
        }
    }
}
