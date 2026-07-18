import SwiftUI

/// Every reel control the coach-mark tutorial can spotlight. Raw string values
/// double as stable identifiers if these ever need to be logged or persisted.
enum TutorialTarget: String, CaseIterable, Hashable {
    case profile
    case speaker
    case mic
    case info
    case share
    case like
    case save
}

/// Collects the on-screen bounds of every tagged control so a single overlay,
/// mounted far above them in the view tree, can resolve each one's frame via
/// `GeometryProxy.subscript(_:)` without any manual position bookkeeping.
struct TutorialAnchorPreferenceKey: PreferenceKey {
    static var defaultValue: [TutorialTarget: Anchor<CGRect>] = [:]

    static func reduce(value: inout [TutorialTarget: Anchor<CGRect>], nextValue: () -> [TutorialTarget: Anchor<CGRect>]) {
        value.merge(nextValue()) { _, latest in latest }
    }
}

extension View {
    /// Tags this view as a tutorial spotlight target. Cheap to leave attached
    /// unconditionally — it only publishes a bounds anchor via preference.
    func tutorialAnchor(_ target: TutorialTarget) -> some View {
        anchorPreference(key: TutorialAnchorPreferenceKey.self, value: .bounds) { [target: $0] }
    }
}
