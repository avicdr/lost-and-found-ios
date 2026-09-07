import UserNotifications

// MARK: - NotificationService

@Observable
final class NotificationService {

    var permissionGranted: Bool = false
    var permissionDenied: Bool = false

    // MARK: - Request Permission
    // Call this at an appropriate moment — NOT on first launch.

    func requestPermission() async {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            permissionGranted = granted
            permissionDenied = !granted
        } catch {
            permissionDenied = true
        }
    }

    // MARK: - Schedule Notifications

    func scheduleMatchFound(itemName: String, location: String) {
        schedule(
            id: "match-\(UUID().uuidString)",
            title: "Possible match found",
            body: "Your lost \(itemName) may have been found near \(location).",
            delay: 2
        )
    }

    func scheduleOwnershipRequest(itemName: String) {
        schedule(
            id: "ownership-\(UUID().uuidString)",
            title: "Ownership request",
            body: "Someone believes your found item \"\(itemName)\" belongs to them.",
            delay: 1
        )
    }

    func scheduleMatchConfirmed(itemName: String) {
        schedule(
            id: "confirmed-\(UUID().uuidString)",
            title: "Match confirmed 🎉",
            body: "\"\(itemName)\" has been successfully matched. Return initiated.",
            delay: 1
        )
    }

    func scheduleActivity(type: ActivityEventType, title: String, message: String, delay: TimeInterval = 1) {
        guard UserDefaults.standard.object(forKey: "sahaay.notifications-enabled") as? Bool != false else { return }
        schedule(id: "activity-\(UUID().uuidString)", title: title, body: message, delay: delay)
    }

    // MARK: - Private

    private func schedule(id: String, title: String, body: String, delay: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }
}
