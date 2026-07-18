import SwiftUI

/// A simple onboarding "beat" screen: illustration, headline, and a Continue button.
struct OnboardingIllustrationView: View {
    let illustrationAssetName: String
    let headline: String
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Image(illustrationAssetName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(.horizontal, 24)
                .padding(.top, 16)

            Text(headline)
                .font(.system(size: 34, weight: .bold, design: .serif))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .padding(.top, 32)
                .padding(.horizontal, 32)

            Spacer()

            Button(action: onContinue) {
                Text("Continue")
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
}

#Preview {
    OnboardingIllustrationView(
        illustrationAssetName: "OnboardingCustomizeIllustration",
        headline: "Customize the app to\nimprove your experience",
        onContinue: {}
    )
}
