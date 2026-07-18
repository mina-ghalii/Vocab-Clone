import SwiftUI

/// An onboarding question with pill-shaped radio options and an optional Skip.
/// In single-select mode (the default), picking an option advances automatically —
/// there's no Continue button. In multi-select mode, options toggle independently
/// and a Continue button is always shown.
struct OnboardingChoiceView: View {
    let headline: String
    let options: [String]
    var showsSkip: Bool = false
    var allowsMultipleSelection: Bool = false
    let onSelect: ([String]) -> Void
    var onSkip: (() -> Void)? = nil

    @State private var selectedOptions: Set<String> = []

    var body: some View {
        VStack(spacing: 0) {
            if showsSkip {
                HStack {
                    Spacer()
                    Button("Skip", action: { onSkip?() })
                        .font(.system(size: 17))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
            }

            Text(headline)
                .font(.system(size: 34, weight: .bold, design: .serif))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .padding(.top, showsSkip ? 24 : 64)
                .padding(.horizontal, 24)

            ScrollView {
                VStack(spacing: 14) {
                    ForEach(options, id: \.self) { option in
                        optionRow(option)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 40)
                .padding(.bottom, 12)
            }
            .frame(maxHeight: .infinity)

            if allowsMultipleSelection {
                Button(action: { onSelect(Array(selectedOptions)) }) {
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.169, green: 0.169, blue: 0.169))
        .ignoresSafeArea(edges: .bottom)
    }

    private func optionRow(_ option: String) -> some View {
        Button(action: { select(option) }) {
            HStack {
                Text(option)
                    .font(.system(size: 19))
                    .foregroundStyle(.white)
                Spacer()
                Circle()
                    .stroke(.white, lineWidth: 1.5)
                    .background(
                        Circle()
                            .fill(Color(red: 0.576, green: 0.757, blue: 0.757))
                            .opacity(selectedOptions.contains(option) ? 1 : 0)
                    )
                    .frame(width: 24, height: 24)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(Color(red: 0.251, green: 0.251, blue: 0.251))
            .clipShape(Capsule())
        }
    }

    private func select(_ option: String) {
        if allowsMultipleSelection {
            if selectedOptions.contains(option) {
                selectedOptions.remove(option)
            } else {
                selectedOptions.insert(option)
            }
            return
        }

        guard selectedOptions.isEmpty else { return }
        selectedOptions = [option]
        // Briefly show the filled radio before advancing so the tap reads as registered.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            onSelect([option])
        }
    }
}

#Preview {
    OnboardingChoiceView(
        headline: "Which topics are you\ninterested in?",
        options: ["Society", "Emotions", "Words in foreign languages", "Human body", "Business", "Other"],
        showsSkip: true,
        allowsMultipleSelection: true,
        onSelect: { _ in }
    )
}
