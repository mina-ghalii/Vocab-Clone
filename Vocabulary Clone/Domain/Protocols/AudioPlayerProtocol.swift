/// Plays a bundled pronunciation clip by its resource file name (e.g. "abandon_uk.mp3").
protocol AudioPlayerProtocol {
    func play(audioFileName: String) throws
    func stop()
}
