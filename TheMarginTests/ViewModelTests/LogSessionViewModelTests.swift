import XCTest
@testable import TheMargin

@MainActor
final class LogSessionViewModelTests: XCTestCase {
    func testCanSaveRequiresWordCountAndMood() {
        let vm = LogSessionViewModel()
        XCTAssertFalse(vm.canSave)

        vm.wordCountText = "500"
        XCTAssertFalse(vm.canSave)

        vm.selectedMood = .steady
        XCTAssertTrue(vm.canSave)
    }

    func testWordCountParsing() {
        let vm = LogSessionViewModel()
        vm.wordCountText = "1,200"
        XCTAssertEqual(vm.parsedWordCount, 1200)

        vm.wordCountText = "abc"
        XCTAssertNil(vm.parsedWordCount)
    }

    func testCanSaveRequiresPositiveWordCount() {
        let vm = LogSessionViewModel()
        vm.wordCountText = "0"
        vm.selectedMood = .steady
        XCTAssertFalse(vm.canSave)
    }
}
