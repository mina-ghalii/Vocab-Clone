import Foundation

/// Drives the mic button's visual + haptic state as the user holds it down to
/// record, releases, and the recording is validated against the target word.
enum PronunciationCheckState: Equatable {
    case idle
    case recording
    case processing
    case correct
    case incorrect(transcript: String)
}
