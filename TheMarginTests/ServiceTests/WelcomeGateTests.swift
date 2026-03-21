import XCTest
@testable import TheMargin

final class WelcomeGateTests: XCTestCase {
    func testShouldShowWelcomeWhenNoProjectsAndNoFlag() {
        XCTAssertTrue(WelcomeGate.shouldShowWelcome(projectCount: 0, hasCompletedFlag: false))
    }

    func testShouldSkipWelcomeWhenProjectsExist() {
        XCTAssertFalse(WelcomeGate.shouldShowWelcome(projectCount: 1, hasCompletedFlag: false))
    }

    func testShouldSkipWelcomeWhenFlagIsSet() {
        XCTAssertFalse(WelcomeGate.shouldShowWelcome(projectCount: 0, hasCompletedFlag: true))
    }
}
