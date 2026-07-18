import SwiftUI

/// The History-style list screen reused for History, Favorites, and Your words:
/// a back header, a "Practice these words" pill, then one `WordListRowView` per entry.
struct WordListView: View {
    @State private var viewModel: WordListViewModel
    let onBack: () -> Void

    @Environment(\.readingTheme) private var theme

    init(
        kind: WordListKind,
        repository: WordHistoryQuerying & WordStateMutating,
        audioPlayer: AudioPlayerProtocol,
        shareImageGenerator: ShareImageGenerating,
        preferredAccent: AudioAccent,
        onBack: @escaping () -> Void
    ) {
        _viewModel = State(initialValue: WordListViewModel(
            kind: kind,
            repository: repository,
            audioPlayer: audioPlayer,
            shareImageGenerator: shareImageGenerator,
            preferredAccent: preferredAccent
        ))
        self.onBack = onBack
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            if viewModel.items.isEmpty {
                Spacer()
                Text(viewModel.kind.emptyMessage)
                    .font(.system(size: 16))
                    .foregroundStyle(theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 14) {

                        ForEach(viewModel.items) { item in
                            WordListRowView(
                                entry: item.entry,
                                progress: item.progress,
                                date: item.date,
                                selectedAccent: viewModel.selectedAccent,
                                onPlay: { viewModel.playAudio(item.entry) },
                                onShare: { viewModel.shareTapped(item.entry) },
                                onLike: { Task { await viewModel.toggleLike(item) } },
                                onSave: { Task { await viewModel.toggleSave(item) } }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 24)
                }
            }
        }
        .background(theme.background.ignoresSafeArea())
        .task { await viewModel.load() }
        .sheet(item: $viewModel.pendingShare) { shareable in
            ActivityView(activityItems: [shareable.image])
        }
    }

    private var header: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 17))
                }
                .foregroundStyle(theme.iconTint)
            }
            Spacer()
            Text(viewModel.kind.title)
                .font(.system(size: 20, weight: .bold, design: .serif))
                .foregroundStyle(theme.primaryText)
            Spacer()
            Color.clear.frame(width: 44, height: 1)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }

}
