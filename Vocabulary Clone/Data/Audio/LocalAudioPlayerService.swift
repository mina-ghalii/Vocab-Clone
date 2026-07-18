import AVFoundation

/// `AudioPlayerProtocol` backed by bundled, pre-recorded pronunciation clips
/// (see `Resources/Audio/uk` and `Resources/Audio/us`). Fully offline — no
/// synthesis, no network, no account.
final class LocalAudioPlayerService: NSObject, AudioPlayerProtocol {
    private var audioPlayer: AVAudioPlayer?

    func play(audioFileName: String) throws {
        audioPlayer?.stop()

        let name = (audioFileName as NSString).deletingPathExtension
        let ext = (audioFileName as NSString).pathExtension
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
            throw LocalAudioPlayerError.resourceNotFound(audioFileName)
        }

        audioPlayer = try AVAudioPlayer(contentsOf: url)
        audioPlayer?.play()
    }

    func stop() {
        audioPlayer?.stop()
    }
}

enum LocalAudioPlayerError: Error {
    case resourceNotFound(String)
}
