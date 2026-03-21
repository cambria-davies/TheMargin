enum InsightsTier: Equatable {
    case empty    // 0 sessions
    case partial  // 1–6 sessions
    case full     // 7+ sessions

    static let unlockThreshold = 7

    static func forSessionCount(_ count: Int) -> InsightsTier {
        switch count {
        case 0: .empty
        case 1..<unlockThreshold: .partial
        default: .full
        }
    }

    static func sessionsToUnlock(currentCount: Int) -> Int {
        max(unlockThreshold - currentCount, 0)
    }

    static func unlockLabel(currentCount: Int) -> String {
        let remaining = sessionsToUnlock(currentCount: currentCount)
        guard remaining > 0 else { return "" }
        return remaining == 1
            ? "1 more session to unlock"
            : "\(remaining) more sessions to unlock"
    }
}
