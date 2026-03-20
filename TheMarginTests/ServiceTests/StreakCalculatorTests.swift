import XCTest
@testable import TheMargin

final class StreakCalculatorTests: XCTestCase {
    private let calendar = Calendar.current

    private func date(daysAgo: Int) -> Date {
        calendar.date(byAdding: .day, value: -daysAgo, to: calendar.startOfDay(for: .now))!
    }

    func testCurrentStreakConsecutiveDays() {
        let dates = [date(daysAgo: 0), date(daysAgo: 1), date(daysAgo: 2)]
        let result = StreakCalculator.calculate(sessionDates: dates)
        XCTAssertEqual(result.current, 3)
    }

    func testCurrentStreakBreaksOnGap() {
        let dates = [date(daysAgo: 0), date(daysAgo: 1), date(daysAgo: 3)]
        let result = StreakCalculator.calculate(sessionDates: dates)
        XCTAssertEqual(result.current, 2)
    }

    func testCurrentStreakZeroWhenNoSessionToday() {
        let dates = [date(daysAgo: 2), date(daysAgo: 3)]
        let result = StreakCalculator.calculate(sessionDates: dates)
        XCTAssertEqual(result.current, 0)
    }

    func testCurrentStreakCountsYesterdayIfNoSessionToday() {
        let dates = [date(daysAgo: 1), date(daysAgo: 2), date(daysAgo: 3)]
        let result = StreakCalculator.calculate(sessionDates: dates)
        XCTAssertEqual(result.current, 3)
        XCTAssertTrue(result.atRisk)
    }

    func testLongestStreakFindsHistoricalMax() {
        let dates = [
            date(daysAgo: 0),
            date(daysAgo: 10), date(daysAgo: 11), date(daysAgo: 12),
            date(daysAgo: 13), date(daysAgo: 14)
        ]
        let result = StreakCalculator.calculate(sessionDates: dates)
        XCTAssertEqual(result.current, 1)
        XCTAssertEqual(result.longest, 5)
    }

    func testMultipleSessionsSameDayCountAsOne() {
        let dates = [date(daysAgo: 0), date(daysAgo: 0), date(daysAgo: 1)]
        let result = StreakCalculator.calculate(sessionDates: dates)
        XCTAssertEqual(result.current, 2)
    }

    func testEmptySessionDates() {
        let result = StreakCalculator.calculate(sessionDates: [])
        XCTAssertEqual(result.current, 0)
        XCTAssertEqual(result.longest, 0)
    }
}
