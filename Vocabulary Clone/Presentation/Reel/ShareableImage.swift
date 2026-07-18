import UIKit

/// Wraps a generated share image so it can drive `.sheet(item:)`, which
/// requires `Identifiable` — `UIImage` itself isn't.
struct ShareableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}
