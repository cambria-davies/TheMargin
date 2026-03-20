import XCTest
@testable import TheMargin

final class TipRotationServiceTests: XCTestCase {
    func testReturnsTipFromPool() {
        let tips = (1...10).map { WritingTip(text: "Tip \($0)", category: .craft) }
        let service = TipRotationService(tips: tips)
        let tip = service.tipForToday()
        XCTAssertNotNil(tip)
        XCTAssertTrue(tips.contains(where: { $0.text == tip!.text }))
    }

    func testCyclesThroughAllBeforeRepeating() {
        let tips = (1...5).map { WritingTip(text: "Tip \($0)", category: .craft) }
        let service = TipRotationService(tips: tips)
        var seen: Set<String> = []
        for _ in 0..<5 {
            let tip = service.nextTip()
            XCTAssertFalse(seen.contains(tip!.text), "Saw \(tip!.text) twice before cycling")
            seen.insert(tip!.text)
        }
        XCTAssertEqual(seen.count, 5)
    }

    func testEmptyPoolReturnsNil() {
        let service = TipRotationService(tips: [])
        XCTAssertNil(service.tipForToday())
    }
}
