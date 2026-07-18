import SwiftUI

/// Onboarding screen that collects the display name the user wants to be called.
/// Continue is disabled until something is typed.
struct OnboardingNameInputView: View {
    let onContinue: (String) -> Void
    let onSkip: () -> Void

    @State private var name = ""

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button("Skip", action: onSkip)
                    .font(.system(size: 17))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)

            Text("What do you want to\nbe called?")
                .font(.system(size: 34, weight: .bold, design: .serif))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .padding(.top, 24)
                .padding(.horizontal, 24)

            TextField("", text: $name, prompt: Text("Your name").foregroundStyle(.white.opacity(0.5)))
                .font(.system(size: 19))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .background(Color(red: 0.251, green: 0.251, blue: 0.251))
                .clipShape(Capsule())
                .padding(.horizontal, 24)
                .padding(.top, 40)
                .submitLabel(.done)

            Spacer()

            Button(action: { onContinue(trimmedName) }) {
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
            .disabled(trimmedName.isEmpty)
            .opacity(trimmedName.isEmpty ? 0.4 : 1)
            .animation(.easeOut(duration: 0.15), value: trimmedName.isEmpty)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.169, green: 0.169, blue: 0.169))
        .ignoresSafeArea(edges: .bottom)
    }
}

#Preview {
    OnboardingNameInputView(onContinue: { _ in }, onSkip: {})
}
