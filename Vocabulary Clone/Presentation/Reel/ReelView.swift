import SwiftUI

/// Vertical, full-screen paging reel of `WordCardView`s. Only a small window of
/// entries is ever materialized (`ReelViewModel` fetches more as the user
/// approaches the end of the loaded window), so this scales to the full word list.
struct ReelView: View {
    @State private var viewModel: ReelViewModel
    var showsWelcomeCard: Bool = false

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
                                }
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .scrollIndicators(.hidden)
            }
            .ignoresSafeArea()

            profileButton
                .padding(.leading, 20)
                .padding(.top, 8)
        }
        .background(theme.background)
        .preferredColorScheme(theme.colorScheme)
        .task {
            await viewModel.start()
        }
        .sheet(item: $viewModel.pendingShare) { shareable in
            ActivityView(activityItems: [shareable.image])
        }
    }

    private var profileButton: some View {
        Button {
            // TODO: present profile screen once it exists.
        } label: {
            Image(systemName: "person.fill")
                .font(.system(size: 20))
                .foregroundStyle(theme.iconTint)
                .frame(width: 52, height: 52)
                .background(theme.chipUnselectedBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}
