import Foundation

/// Records the user's voice and transcribes it entirely on-device. Abstracted
/// behind a protocol so `ReelViewModel` can be driven by a fake in tests, and
/// so the underlying speech engine (legacy `SFSpeechRecognizer` vs. the newer
/// `SpeechAnalyzer`/`SpeechTranscriber`) can evolve without touching call sites.
protocol SpeechRecognizing {
    /// Prompts for microphone + speech recognition permission if not already
    /// determined. Returns whether both are authorized.
    func requestAuthorization() async -> Bool

    /// Starts capturing microphone audio. Throws if authorization is missing
    /// or the audio session can't be configured.
    func startRecording() throws

    /// Stops capturing and returns the best transcript for what was recorded.
    func stopRecording() async throws -> String
}
