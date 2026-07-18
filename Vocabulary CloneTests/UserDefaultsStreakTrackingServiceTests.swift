import XCTest
@testable import Vocabulary_Clone

final class UserDefaultsStreakTrackingServiceTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!
    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        suiteName = "UserDefaultsStreakTrackingServiceTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        calendar = nil
        suiteName = nil
        super.tearDown()
    }

    private func makeService(now: @escaping () -> Date) -> UserDefaultsStreakTrackingService {
        UserDefaultsStreakTrackingService(defaults: defaults, calendar: calendar, now: now)
    }

    private func statusLabel(_ status: StreakDayStatus) -> String {
        switch status {
        case .completed: return "completed"
        case .missed: return "missed"
        case .upcoming: return "upcoming"
        }
    }

    func testRecordAppOpenedReturnsTrueOnFirstCallOfDayAndFalseAfter() {
        let today = Date()
        let service = makeService(now: { today })

        XCTAssertTrue(service.recordAppOpened())
        XCTAssertFalse(service.recordAppOpened())
    }

    func testStreakCountsConsecutiveDaysEndingToday() {
        var currentDate = Date()
        let service = makeService(now: { currentDate })

        XCTAssertTrue(service.recordAppOpened())
        currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        XCTAssertTrue(service.recordAppOpened())
        currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        XCTAssertTrue(service.recordAppOpened())

        XCTAssertEqual(service.currentSummary().currentStreakCount, 3)
    }

    func testStreakStaysAliveIfTodayNotYetOpenedButYesterdayWas() {
        var currentDate = Date()
        let service = makeService(now: { currentDate })
        XCTAssertTrue(service.recordAppOpened())

        currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!

        XCTAssertEqual(service.currentSummary().currentStreakCount, 1)
    }

    func testStreakResetsAfterAGapDay() {
        var currentDate = Date()
        let service = makeService(now: { currentDate })
        XCTAssertTrue(service.recordAppOpened())

        currentDate = calendar.date(byAdding: .day, value: 2, to: currentDate)!

        XCTAssertEqual(service.currentSummary().currentStreakCount, 0)
    }

    func testStreakIsZeroWhenNoDaysOpened() {
        let service = makeService(now: { Date() })

        XCTAssertEqual(service.currentSummary().currentStreakCount, 0)
    }

    func testWeekWindowSpansThreeDaysBeforeAndAfterToday() {
        let today = Date()
        let service = makeService(now: { today })
        _ = service.recordAppOpened()

        let days = service.currentSummary().days

        XCTAssertEqual(days.count, 7)
        XCTAssertEqual(days.filter(\.isToday).count, 1)
        XCTAssertEqual(statusLabel(days.first(where: \.isToday)!.status), "completed")
        XCTAssertTrue(days.suffix(3).allSatisfy { statusLabel($0.status) == "upcoming" })
    }

    func testWeekWindowMarksUnopenedPastDaysAsMissed() {
        let today = Date()
        let service = makeService(now: { today })
        _ = service.recordAppOpened()

        let days = service.currentSummary().days
        let pastDays = days.prefix(3)

        XCTAssertTrue(pastDays.allSatisfy { statusLabel($0.status) == "missed" })
    }

    func testWeekWindowMarksOpenedPastDaysAsCompleted() {
        var currentDate = Date()
        let service = makeService(now: { currentDate })
        XCTAssertTrue(service.recordAppOpened())
        currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        XCTAssertTrue(service.recordAppOpened())

        let days = service.currentSummary().days
        let yesterday = days[2]

        XCTAssertFalse(yesterday.isToday)
        XCTAssertEqual(statusLabel(yesterday.status), "completed")
    }
}
