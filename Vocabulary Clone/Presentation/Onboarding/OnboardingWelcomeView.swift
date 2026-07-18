import SwiftUI

/// First screen of the onboarding flow: illustration, value proposition, and social proof.
struct OnboardingWelcomeView: View {
    let onGetStarted: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Image("OnboardingWelcomeIllustration")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(.horizontal, 24)
                .padding(.top, 16)

            VStack(spacing: 12) {
                Text("Expand your Vocabulary\nin 1 minute a day")
                    .font(.system(size: 34, weight: .bold, design: .serif))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)

                Text("Learn 10,000+ new words with a new daily habit that takes just 1 minute")
                    .font(.system(size: 17))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(.horizontal, 32)
            .padding(.top, 28)

            Spacer(minLength: 24)

            statsRow
                .padding(.bottom, 28)

            Button(action: onGetStarted) {
                Text("Get started")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
            }
            .background(Color(red: 0.576, green: 0.757, blue: 0.757))
            .clipShape(Capsule())
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.169, green: 0.169, blue: 0.169).ignoresSafeArea())
    }

    private var statsRow: some View {
        HStack(spacing: 0) {
            statColumn(value: "350 million", label: "words learned")
            Spacer()
            ratingBadge
            Spacer()
            statColumn(value: "14 million", label: "downloads")
        }
        .padding(.horizontal, 28)
    }

    private func statColumn(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 19, weight: .bold))
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.7))
        }
        .foregroundStyle(.white)
    }

    private var ratingBadge: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "laurel.leading")
                Text("4.8")
                    .font(.system(size: 26, weight: .bold, design: .serif))
                Image(systemName: "laurel.trailing")
            }
            .foregroundStyle(.white)

            HStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: 11))
                }
            }
            .foregroundStyle(Color(red: 0.875, green: 0.710, blue: 0.118))
        }
    }
}

#Preview {
    OnboardingWelcomeView(onGetStarted: {})
}
