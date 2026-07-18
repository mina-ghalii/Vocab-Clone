import SwiftUI

/// `ShareImageGenerating` backed by SwiftUI's `ImageRenderer`.
@MainActor
struct WordCardImageGenerator: ShareImageGenerating {
    func image(for entry: WordEntry) -> UIImage? {
        let renderer = ImageRenderer(content: ShareableWordCardView(entry: entry))
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }
}
