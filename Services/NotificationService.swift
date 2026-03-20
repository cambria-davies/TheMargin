import UserNotifications

enum NotificationService {
    struct ReminderState: Sendable {
        let isAuthorized: Bool
        let isScheduled: Bool
        let hour: Int?
        let minute: Int?
    }

    static func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound])
        } catch {
            return false
        }
    }

    static func scheduleDailyReminder(at hour: Int, minute: Int) async throws {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["daily-reminder"])

        let content = UNMutableNotificationContent()
        content.title = "Time to write"
        content.body = "Your manuscript is waiting."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "daily-reminder", content: content, trigger: trigger)

        try await center.add(request)
    }

    static func cancelDailyReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["daily-reminder"])
    }

    static func currentReminderState() async -> ReminderState {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        let requests = await center.pendingNotificationRequests()
        let reminder = requests.first(where: { $0.identifier == "daily-reminder" })
        let trigger = reminder?.trigger as? UNCalendarNotificationTrigger

        return ReminderState(
            isAuthorized: settings.authorizationStatus == .authorized
                || settings.authorizationStatus == .provisional,
            isScheduled: reminder != nil,
            hour: trigger?.dateComponents.hour,
            minute: trigger?.dateComponents.minute
        )
    }
}
