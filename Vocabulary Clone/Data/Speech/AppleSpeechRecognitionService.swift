import AVFoundation
import Speech

/// `SpeechRecognizing` backed by `SFSpeechRecognizer` with on-device
/// recognition forced on — no audio or transcript ever leaves the device,
/// matching this app's offline-only design (see `LocalAudioPlayerService`).
final class AppleSpeechRecognitionService: SpeechRecognizing {
    private let audioEngine = AVAudioEngine()
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let transcriptBox = TranscriptContinuationBox()

    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var latestTranscript = ""

    func requestAuthorization() async -> Bool {
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        guard speechStatus == .authorized else { return false }

        return await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    func startRecording() throws {
        recognitionTask?.cancel()
        recognitionTask = nil
        latestTranscript = ""

        guard let recognizer, recognizer.isAvailable else {
            throw SpeechRecognitionError.recognizerUnavailable
        }

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = true
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            if let result {
                self.latestTranscript = result.bestTranscription.formattedString
                if result.isFinal {
                    self.transcriptBox.resume(with: self.latestTranscript)
                }
            }
            if error != nil {
                self.transcriptBox.resume(with: self.latestTranscript)
            }
        }
    }

    func stopRecording() async throws -> String {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()

        // The recognizer delivers its final result asynchronously after
        // `endAudio()`; race it against a timeout so a silent/empty
        // recording can't hang this indefinitely.
        let transcript = await withCheckedContinuation { (continuation: CheckedContinuation<String, Never>) in
            transcriptBox.set(continuation)
            Task { [weak self] in
                try? await Task.sleep(for: .seconds(2))
                guard let self else { return }
                self.transcriptBox.resume(with: self.latestTranscript)
            }
        }

        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        return transcript
    }
}

enum SpeechRecognitionError: Error {
    case recognizerUnavailable
}

/// Guards a `CheckedContinuation` against the double-resume crash that would
/// otherwise be possible when the recognition callback and the stop-recording
/// timeout race each other from different queues.
private final class TranscriptContinuationBox: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<String, Never>?

    func set(_ continuation: CheckedContinuation<String, Never>?) {
        lock.lock()
        defer { lock.unlock() }
        self.continuation = continuation
    }

    func resume(with value: String) {
        lock.lock()
        let continuation = self.continuation
        self.continuation = nil
        lock.unlock()
        continuation?.resume(returning: value)
    }
}
