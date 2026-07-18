import UIKit

/// Renders a `WordEntry` into a shareable image. `ImageRenderer`-based
/// implementations must run on the main actor.
@MainActor
protocol ShareImageGenerating {
    func image(for entry: WordEntry) -> UIImage?
}
