import XCTest
@testable import TheMargin

@MainActor
final class TimerViewModelTests: XCTestCase {
    func testInitialStateIsReady() {
        let vm = TimerViewModel()
        XCTAssertEqual(vm.state, .ready)
        XCTAssertEqual(vm.elapsedSeconds, 0)
    }

    func testStartTransitionsToRunning() {
        let vm = TimerViewModel()
        vm.start()
        XCTAssertEqual(vm.state, .running)
    }

    func testPauseTransitionsToPaused() {
        let vm = TimerViewModel()
        vm.start()
        vm.pause()
        XCTAssertEqual(vm.state, .paused)
    }

    func testResumeTransitionsToRunning() {
        let vm = TimerViewModel()
        vm.start()
        vm.pause()
        vm.resume()
        XCTAssertEqual(vm.state, .running)
    }

    func testStopTransitionsToStopped() {
        let vm = TimerViewModel()
        vm.start()
        vm.stop()
        XCTAssertEqual(vm.state, .stopped)
    }

    func testFormattedTimeDisplay() {
        let vm = TimerViewModel()
        vm.elapsedSeconds = 3661
        XCTAssertEqual(vm.formattedTime, "1:01:01")

        vm.elapsedSeconds = 125
        XCTAssertEqual(vm.formattedTime, "2:05")
    }
}
