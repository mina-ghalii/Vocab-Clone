import SwiftUI

/// Onboarding screen for picking the pronunciation accent. Tapping the play button
/// previews that accent's recording of "hello" via `audioPlayer`; tapping the row
/// selects it. British is preselected to match the reel's default.
struct OnboardingVoicePickerView: View {
    let audioPlayer: AudioPlayerProtocol
    let onContinue: (AudioAccent) -> Void

    @State private var selectedAccent: AudioAccent = .uk

    private let waveformHeights: [CGFloat] = [6, 14, 9, 18, 8, 12, 16, 7, 13, 10, 17, 9, 6, 14, 11, 8]

    var body: some View {
        VStack(spacing: 0) {
            Text("Choose an accent to\npronounce words")
                .font(.system(size: 34, weight: .bold, design: .serif))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .padding(.top, 64)
                .padding(.horizontal, 24)

            VStack(spacing: 14) {
                ForEach(AudioAccent.allCases) { accent in
                    accentRow(accent)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 40)

            Spacer()

            Button(action: { onContinue(selectedAccent) }) {
                Text("Save accent selection")
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
        .onDisappear { audioPlayer.stop() }
    }

    private func accentRow(_ accent: AudioAccent) -> some View {
        let isSelected = selectedAccent == accent
        let textColor: Color = isSelected ? .black : .white

        return HStack(spacing: 14) {
            Button(action: { try? audioPlayer.play(audioFileName: previewFileName(for: accent)) }) {
                Image(systemName: "play.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(textColor)
                    .frame(width: 24, height: 24)
            }

            Text(accent.title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(textColor)

            Spacer()

            waveform(color: textColor.opacity(0.5))

            Circle()
                .stroke(textColor, lineWidth: 1.5)
                .background(Circle().fill(isSelected ? Color.white : .clear))
                .frame(width: 26, height: 26)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(isSelected ? Color(red: 0.576, green: 0.757, blue: 0.757) : Color(red: 0.251, green: 0.251, blue: 0.251))
        .clipShape(Capsule())
        .contentShape(Capsule())
        .onTapGesture { selectedAccent = accent }
    }

    private func waveform(color: Color) -> some View {
        HStack(spacing: 2) {
            ForEach(Array(waveformHeights.enumerated()), id: \.offset) { _, height in
                Capsule()
                    .fill(color)
                    .frame(width: 2, height: height)
            }
        }
        .frame(height: 20)
    }

    private func previewFileName(for accent: AudioAccent) -> String {
        accent == .uk ? "hello_uk.mp3" : "hello_us.mp3"
    }
}

#Preview {
    OnboardingVoicePickerView(audioPlayer: PreviewSilentAudioPlayer(), onContinue: { _ in })
}

private struct PreviewSilentAudioPlayer: AudioPlayerProtocol {
    func play(audioFileName: String) throws {}
    func stop() {}
}
