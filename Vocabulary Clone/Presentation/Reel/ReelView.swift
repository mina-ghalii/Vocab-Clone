import SwiftUI

/// Vertical, full-screen paging reel of `WordCardView`s. Only a small window of
/// entries is ever materialized (`ReelViewModel` fetches more as the user
/// approaches the end of the loaded window), so this scales to the full word list.
struct ReelView: View {
    @State private var viewModel: ReelViewModel
    var showsWelcomeCard: Bool = false

    @State private var isProfilePresented = false

    @AppStorage("hasSeenReelTutorial") private var hasSeenReelTutorial = false
    @State private var isTutorialPresented = false

    @Environment(\.readingTheme) private var theme

    init(viewModel: ReelViewModel, showsWelcomeCard: Bool = false) {
        _viewModel = State(initialValue: viewModel)
        self.showsWelcomeCard = showsWelcomeCard
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            GeometryReader { proxy in
                ScrollView(.vertical) {
                    LazyVStack(spacing: 0) {
                        if showsWelcomeCard {
                            WelcomeCardView()
                                .frame(width: proxy.size.width, height: proxy.size.height)
                        }

                        ForEach(Array(viewModel.loadedEntries.enumerated()), id: \.element.id) { index, entry in
                            WordCardView(entry: entry, viewModel: viewModel)
                                .frame(width: proxy.size.width, height: proxy.size.height)
                                .onAppear {
                                    Task { await viewModel.cardAppeared(entry, at: index) }
                                    if index == 0 { scheduleTutorialIfNeeded() }
                                }
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .scrollIndicators(.hidden)
            }
            .ignoresSafeArea()

            topBar
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .animation(.easeInOut(duration: 0.3), value: viewModel.isStreakPanelVisible)
        }
        .overlayPreferenceValue(TutorialAnchorPreferenceKey.self) { anchors in
            if isTutorialPresented {
                ReelTutorialOverlay(anchors: anchors, onFinished: dismissTutorial)
            }
        }
        .background(theme.background)
        .preferredColorScheme(theme.colorScheme)
        .task {
            await viewModel.start()
        }
        .task {
            await viewModel.presentStreakPanelIfNeeded()
        }
        .sheet(item: $viewModel.pendingShare) { shareable in
            ActivityView(activityItems: [shareable.image])
        }
        .sheet(item: $viewModel.pendingInfo) { presentation in
            WordInfoSheetView(
                entry: presentation.entry,
                selectedAccent: viewModel.selectedAccent,
                onPlay: { viewModel.playCurrentAudio(for: presentation.entry) },
                onSelectAccent: { viewModel.selectAccent($0) },
                onDismiss: { viewModel.pendingInfo = nil }
            )
            .environment(\.readingTheme, theme)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.hidden)
            .presentationCornerRadius(28)
        }
        .fullScreenCover(isPresented: $isProfilePresented) {
            ProfileView(
                repository: viewModel.repository,
                audioPlayer: viewModel.audioPlayer,
                shareImageGenerator: viewModel.shareImageGenerator,
                preferredAccent: viewModel.selectedAccent
            )
            .environment(\.readingTheme, theme)
        }
    }

    /// Waits for the first card's layout to settle and, if a streak panel is
    /// about to take over the top bar, for that to clear too — otherwise the
    /// tutorial's first step would spotlight an empty top-left corner.
    private func scheduleTutorialIfNeeded() {
        guard !hasSeenReelTutorial, !isTutorialPresented else { return }
        Task {
            try? await Task.sleep(for: .seconds(0.6))
            while viewModel.isStreakPanelVisible {
                try? await Task.sleep(for: .seconds(0.3))
            }
            guard !hasSeenReelTutorial else { return }
            withAnimation(.easeOut(duration: 0.3)) {
                isTutorialPresented = true
            }
        }
    }

    private func dismissTutorial() {
        hasSeenReelTutorial = true
        withAnimation(.easeOut(duration: 0.25)) {
            isTutorialPresented = false
        }
    }

    @ViewBuilder
    private var topBar: some View {
        if viewModel.isStreakPanelVisible, let streakSummary = viewModel.streakSummary {
            StreakPanelView(summary: streakSummary)
                .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
        } else {
            profileButton
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var profileButton: some View {
        Button {
            isProfilePresented = true
        } label: {
            Image(systemName: "person.fill")
                .font(.system(size: 20))
                .foregroundStyle(theme.iconTint)
                .frame(width: 52, height: 52)
                .background(theme.chipUnselectedBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .tutorialAnchor(.profile)
    }
}
