import XCTest
@testable import TheMargin

final class InsightsTierTests: XCTestCase {
    func testTierOneWithZeroSessions() {
        XCTAssertEqual(InsightsTier.forSessionCount(0), .empty)
    }

    func testTierTwoWithFewSessions() {
        XCTAssertEqual(InsightsTier.forSessionCount(1), .partial)
        XCTAssertEqual(InsightsTier.forSessionCount(6), .partial)
    }

    func testTierThreeWithEnoughSessions() {
        XCTAssertEqual(InsightsTier.forSessionCount(7), .full)
        XCTAssertEqual(InsightsTier.forSessionCount(100), .full)
    }

    func testSessionsToUnlock() {
        XCTAssertEqual(InsightsTier.sessionsToUnlock(currentCount: 3), 4)
        XCTAssertEqual(InsightsTier.sessionsToUnlock(currentCount: 6), 1)
        XCTAssertEqual(InsightsTier.sessionsToUnlock(currentCount: 7), 0)
    }

    func testUnlockLabelSingular() {
        XCTAssertEqual(InsightsTier.unlockLabel(currentCount: 6), "1 more session to unlock")
    }

    func testUnlockLabelPlural() {
        XCTAssertEqual(InsightsTier.unlockLabel(currentCount: 3), "4 more sessions to unlock")
    }
}
