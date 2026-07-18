import Foundation

/// Whether a day in the streak strip was opened, missed, or hasn't happened yet.
enum StreakDayStatus {
    case completed
    case missed
    case upcoming
}

/// One day in the rolling streak strip.
struct StreakDay: Identifiable {
    let date: Date
    let weekdaySymbol: String
    let status: StreakDayStatus
    let isToday: Bool

    var id: Date { date }
}

/// The user's current streak count plus a week-wide window of day statuses
/// centered on today, used to render the streak panel.
struct StreakSummary {
    let currentStreakCount: Int
    let days: [StreakDay]
}
