import Foundation

/// Tracks which calendar days the app was opened and derives streak state from it.
protocol StreakTracking {
    /// Records today as opened. Returns `true` only the first time this is
    /// called on a given calendar day, so callers can show streak UI once daily.
    @discardableResult
    func recordAppOpened() -> Bool

    /// The current streak and a rolling window of day statuses around today.
    func currentSummary() -> StreakSummary
}
