import Foundation

class TipRotationService {
    private let tips: [WritingTip]
    private var shuffled: [WritingTip] = []
    private var index: Int = 0

    private static let lastTipDateKey = "lastTipDate"
    private static let lastTipIndexKey = "lastTipIndex"

    init(tips: [WritingTip]) {
        self.tips = tips
        reshuffle()
    }

    func tipForToday() -> WritingTip? {
        guard !tips.isEmpty else { return nil }

        let today = Calendar.current.startOfDay(for: .now)
        let defaults = UserDefaults.standard

        if let lastDate = defaults.object(forKey: Self.lastTipDateKey) as? Date,
           Calendar.current.isDate(lastDate, inSameDayAs: today) {
            let savedIndex = defaults.integer(forKey: Self.lastTipIndexKey)
            if savedIndex < shuffled.count {
                return shuffled[savedIndex]
            }
        }

        let tip = nextTip()
        defaults.set(today, forKey: Self.lastTipDateKey)
        defaults.set(index - 1, forKey: Self.lastTipIndexKey)
        return tip
    }

    func nextTip() -> WritingTip? {
        guard !tips.isEmpty else { return nil }
        if index >= shuffled.count {
            reshuffle()
        }
        let tip = shuffled[index]
        index += 1
        return tip
    }

    private func reshuffle() {
        shuffled = tips.shuffled()
        index = 0
    }
}
