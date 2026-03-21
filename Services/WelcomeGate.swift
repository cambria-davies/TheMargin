enum WelcomeGate {
    static func shouldShowWelcome(projectCount: Int, hasCompletedFlag: Bool) -> Bool {
        !hasCompletedFlag && projectCount == 0
    }
}
