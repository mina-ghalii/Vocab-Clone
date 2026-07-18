import SwiftUI

/// The reel's one-time first page, shown only right after onboarding finishes.
/// Mirrors `WordCardView`'s vertical rhythm so paging from it to the first real
/// word card feels continuous.
struct WelcomeCardView: View {
    @Environment(\.readingTheme) private var theme

    var body: some View {
        ZStack {
            theme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                Text("Welcome to Vocabulary")
                    .font(.system(size: 34, weight: .bold, design: .serif))
                    .foregroundStyle(theme.primaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()
                Spacer()

                VStack(spacing: 8) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 22, weight: .light))
                    Text("Swipe up")
                        .font(.system(size: 17))
                }
                .foregroundStyle(theme.secondaryText)
                .padding(.bottom, 48)
            }
        }
    }
}

#Preview {
    WelcomeCardView()
}
