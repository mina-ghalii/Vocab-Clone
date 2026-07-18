import SwiftUI

private struct ReelTutorialStep {
    let target: TutorialTarget
    let icon: String
    let title: String
    let message: String
}

/// Spatial (top-to-bottom, then left-to-right along the action rail) rather than
/// the raw list order — walking the screen this way means the spotlight only ever
/// travels downward, which reads far calmer than hopping around the card.
private let reelTutorialSteps: [ReelTutorialStep] = [
    ReelTutorialStep(
        target: .profile,
        icon: "person.fill",
        title: "Your profile",
        message: "See your streak, saved words, and settings here."
    ),
    ReelTutorialStep(
        target: .speaker,
        icon: "speaker.wave.2.fill",
        title: "Hear it",
        message: "Tap the speaker to hear the word pronounced."
    ),
    ReelTutorialStep(
        target: .mic,
        icon: "mic.fill",
        title: "Practice speaking",
        message: "Press and hold, say the word out loud, then release to check yourself."
    ),
    ReelTutorialStep(
        target: .info,
        icon: "info.circle.fill",
        title: "Word info",
        message: "Tap for more detail about this word."
    ),
    ReelTutorialStep(
        target: .share,
        icon: "square.and.arrow.up.fill",
        title: "Share",
        message: "Send this word card to a friend."
    ),
    ReelTutorialStep(
        target: .like,
        icon: "heart.fill",
        title: "Like",
        message: "Like the words you enjoy or want to remember."
    ),
    ReelTutorialStep(
        target: .save,
        icon: "bookmark.fill",
        title: "Save",
        message: "Save this word to review it again later."
    ),
]

/// Full-screen coach-mark walkthrough: dims everything but the current control,
/// explains it in a nearby card, and steps forward on "Next" until the last stop.
/// Mount with `.overlayPreferenceValue(TutorialAnchorPreferenceKey.self)` over the
/// content whose buttons carry `.tutorialAnchor(_:)`, so anchors resolve in the
/// same coordinate space as the reel itself.
struct ReelTutorialOverlay: View {
    let anchors: [TutorialTarget: Anchor<CGRect>]
    let onFinished: () -> Void

    @State private var stepIndex = 0
    @State private var hasAppeared = false

    private var step: ReelTutorialStep { reelTutorialSteps[stepIndex] }
    private var isLastStep: Bool { stepIndex == reelTutorialSteps.count - 1 }

    var body: some View {
        GeometryReader { proxy in
            let rect = spotlightRect(in: proxy)
            let placeBelow = rect.midY < proxy.size.height * 0.5

            ZStack {
                dimmedBackdrop(cutout: rect)
                spotlightGlow(rect: rect)
                calloutLayout(rect: rect, proxy: proxy, placeBelow: placeBelow)
            }
        }
        .ignoresSafeArea()
        .opacity(hasAppeared ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.35)) {
                hasAppeared = true
            }
        }
    }

    // MARK: - Spotlight

    private func spotlightRect(in proxy: GeometryProxy) -> CGRect {
        guard let anchor = anchors[step.target] else {
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
            return CGRect(origin: center, size: .zero)
        }
        return proxy[anchor].insetBy(dx: -14, dy: -14)
    }

    private func cornerRadius(for rect: CGRect) -> CGFloat {
        min(rect.width, rect.height) / 2
    }

    private func dimmedBackdrop(cutout rect: CGRect) -> some View {
        Color.black.opacity(0.75)
            .reverseMask {
                RoundedRectangle(cornerRadius: cornerRadius(for: rect), style: .continuous)
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: stepIndex)
            .contentShape(Rectangle())
            .onTapGesture {} // swallow taps so only the tutorial's own controls are interactive
    }

    private func spotlightGlow(rect: CGRect) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius(for: rect), style: .continuous)
            .stroke(Color.white.opacity(0.9), lineWidth: 2)
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
            .shadow(color: .white.opacity(0.55), radius: 12)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: stepIndex)
    }

    // MARK: - Callout

    /// Fixed-height spacers (computed from the target's already-known rect) push
    /// the card just clear of the spotlight without ever needing to measure the
    /// card itself first — a two-pass "measure, then position" layout isn't needed.
    @ViewBuilder
    private func calloutLayout(rect: CGRect, proxy: GeometryProxy, placeBelow: Bool) -> some View {
        VStack(spacing: 0) {
            if placeBelow {
                Color.clear.frame(height: rect.maxY + 24)
                calloutCard
                    .transition(calloutTransition(placeBelow: true))
                Spacer(minLength: 0)
            } else {
                Spacer(minLength: 0)
                calloutCard
                    .transition(calloutTransition(placeBelow: false))
                Color.clear.frame(height: max(0, proxy.size.height - rect.minY + 24))
            }
        }
        .padding(.horizontal, 24)
        .frame(width: proxy.size.width, height: proxy.size.height)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: stepIndex)
    }

    private func calloutTransition(placeBelow: Bool) -> AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .move(edge: placeBelow ? .top : .bottom)).combined(with: .scale(scale: 0.94)),
            removal: .opacity
        )
    }

    private var calloutCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: step.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(Color.white.opacity(0.16), in: Circle())

                Text(step.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()

                Button("Skip", action: onFinished)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.55))
            }

            Text(step.message)
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                progressDots
                Spacer()
                nextButton
            }
        }
        .padding(18)
        .frame(maxWidth: 320)
        .background(Color(white: 0.14), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.4), radius: 20, y: 8)
        .id(stepIndex)
    }

    private var progressDots: some View {
        HStack(spacing: 6) {
            ForEach(reelTutorialSteps.indices, id: \.self) { index in
                Capsule()
                    .fill(Color.white.opacity(index == stepIndex ? 0.95 : 0.28))
                    .frame(width: index == stepIndex ? 16 : 6, height: 6)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: stepIndex)
    }

    private var nextButton: some View {
        Button(action: advance) {
            Text(isLastStep ? "Got it" : "Next")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.black)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.white, in: Capsule())
        }
    }

    private func advance() {
        guard !isLastStep else {
            onFinished()
            return
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            stepIndex += 1
        }
    }
}

private extension View {
    /// Punches a `content`-shaped hole out of `self` using a destination-out
    /// blend, composited as a single layer so the hole is actually transparent
    /// rather than just visually covered.
    @ViewBuilder
    func reverseMask<Mask: View>(@ViewBuilder _ mask: () -> Mask) -> some View {
        self.mask {
            Rectangle()
                .overlay(alignment: .topLeading) {
                    mask()
                        .blendMode(.destinationOut)
                }
                .compositingGroup()
        }
    }
}
