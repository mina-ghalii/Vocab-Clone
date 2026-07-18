import Foundation

/// Persists opened calendar days as "yyyy-MM-dd" strings in `UserDefaults` and
/// derives streak state from them.
final class UserDefaultsStreakTrackingService: StreakTracking {
    private let defaults: UserDefaults
    private let calendar: Calendar
    private let now: () -> Date

    private static let openedDaysKey = "streakOpenedDays"
    private static let weekdaySymbols = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        return formatter
    }()

    nonisolated deinit {}

    init(defaults: UserDefaults = .standard, calendar: Calendar = .current, now: @escaping () -> Date = Date.init) {
        self.defaults = defaults
        self.calendar = calendar
        self.now = now
    }

    @discardableResult
    func recordAppOpened() -> Bool {
        var days = openedDayKeys
        let todayKey = key(for: now())
        guard !days.contains(todayKey) else { return false }
        days.insert(todayKey)
        defaults.set(Array(days), forKey: Self.openedDaysKey)
        return true
    }

    func currentSummary() -> StreakSummary {
        StreakSummary(currentStreakCount: currentStreak(), days: weekWindow())
    }

    private var openedDayKeys: Set<String> {
        Set(defaults.stringArray(forKey: Self.openedDaysKey) ?? [])
    }

    private func key(for date: Date) -> String {
        Self.dayFormatter.string(from: date)
    }

    private func currentStreak() -> Int {
        let days = openedDayKeys
        let today = calendar.startOfDay(for: now())

        var cursor = today
        if !days.contains(key(for: cursor)) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor) else { return 0 }
            cursor = yesterday
        }

        var streak = 0
        while days.contains(key(for: cursor)) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }

    /// Three days back through three days ahead of today.
    private func weekWindow() -> [StreakDay] {
        let days = openedDayKeys
        let todayStart = calendar.startOfDay(for: now())

        return (-3...3).compactMap { offset -> StreakDay? in
            guard let date = calendar.date(byAdding: .day, value: offset, to: todayStart) else { return nil }
            let status: StreakDayStatus
            if offset > 0 {
                status = .upcoming
            } else if days.contains(key(for: date)) {
                status = .completed
            } else {
                status = .missed
            }
            let weekday = calendar.component(.weekday, from: date)
            return StreakDay(
                date: date,
                weekdaySymbol: Self.weekdaySymbols[weekday - 1],
                status: status,
                isToday: offset == 0
            )
        }
    }
}
