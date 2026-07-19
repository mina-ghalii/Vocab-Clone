import SwiftUI
import UIKit

/// WhatsApp-style press-and-hold mic button: press down to start recording,
/// release to stop and validate against the current word. Pulsing rings +
/// haptics mark "recording," a morphing checkmark/xmark marks the result.
struct MicButtonView: View {
    let state: PronunciationCheckState
    let onPress: () -> Void
    let onRelease: () -> Void

    @State private var isPressing = false
    @State private var isPulsing = false
    @State private var isCaptionBreathing = false
    @State private var impactGenerator = UIImpactFeedbackGenerator(style: .medium)
    @State private var notificationGenerator = UINotificationFeedbackGenerator()

    @Environment(\.readingTheme) private var theme

    private let diameter: CGFloat = 76

    var body: some View {
        VStack(spacing: 12) {
            micCircle
            captionLabel
        }
        .onAppear {
            impactGenerator.prepare()
            isCaptionBreathing = true
        }
    }

    private var micCircle: some View {
        ZStack {
            if state == .recording {
                pulseRing(delay: 0)
                pulseRing(delay: 0.6)
            }

            Circle()
                .fill(backgroundColor)
                .frame(width: diameter, height: diameter)
                .scaleEffect(state == .recording ? 1.1 : 1.0)
                .shadow(color: .black.opacity(0.25), radius: 12, y: 6)

            icon
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(iconColor)
                .contentTransition(.symbolEffect(.replace))
        }
        .tutorialAnchor(.mic)
        .frame(width: diameter + 60, height: diameter + 60)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: state)
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !isPressing else { return }
                    isPressing = true
                    impactGenerator.impactOccurred()
                    onPress()
                }
                .onEnded { _ in
                    isPressing = false
                    onRelease()
                }
        )
        .onChange(of: state) { _, newState in
            switch newState {
            case .recording:
                isPulsing = true
                isCaptionBreathing = false
            case .correct:
                notificationGenerator.notificationOccurred(.success)
                isPulsing = false
                isCaptionBreathing = false
            case .incorrect:
                notificationGenerator.notificationOccurred(.error)
                isPulsing = false
                isCaptionBreathing = false
            case .processing:
                isPulsing = false
                isCaptionBreathing = false
            case .idle:
                isPulsing = false
                isCaptionBreathing = true
            }
        }
    }

    private var captionLabel: some View {
        Text(captionText)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(captionForeground)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(captionBackground, in: Capsule())
            .contentTransition(.opacity)
            .animation(.easeInOut(duration: 0.2), value: state)
            .opacity(isCaptionBreathing ? 0.55 : 1)
            .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: isCaptionBreathing)
    }

    private var captionText: String {
        switch state {
        case .idle: return "Hold to speak"
        case .recording: return "Say the word aloud"
        case .processing: return "Checking…"
        case .correct: return "Nailed it!"
        case .incorrect: return "Try again"
        }
    }

    private var captionForeground: Color {
        switch state {
        case .idle, .processing: return theme.secondaryText
        case .recording, .correct: return .green
        case .incorrect: return .red
        }
    }

    private var captionBackground: Color {
        switch state {
        case .idle, .processing: return theme.chipUnselectedBackground
        case .recording, .correct: return Color.green.opacity(0.15)
        case .incorrect: return Color.red.opacity(0.15)
        }
    }

    private func pulseRing(delay: Double) -> some View {
        Circle()
            .stroke(Color.green.opacity(0.45), lineWidth: 2)
            .frame(width: diameter, height: diameter)
            .scaleEffect(isPulsing ? 1.9 : 1.0)
            .opacity(isPulsing ? 0 : 0.7)
            .animation(
                .easeOut(duration: 1.4).repeatForever(autoreverses: false).delay(delay),
                value: isPulsing
            )
    }

    @ViewBuilder
    private var icon: some View {
        switch state {
        case .idle, .recording:
            Image(systemName: "mic.fill")
        case .processing:
            ProgressView()
                .tint(iconColor)
        case .correct:
            Image(systemName: "checkmark")
        case .incorrect:
            Image(systemName: "xmark")
        }
    }

    private var backgroundColor: Color {
        switch state {
        case .idle, .processing: return theme.chipSelectedBackground
        case .recording: return .green
        case .correct: return .green
        case .incorrect: return .red
        }
    }

    private var iconColor: Color {
        switch state {
        case .idle, .processing: return theme.chipSelectedText
        case .recording, .correct, .incorrect: return .white
        }
    }
}
