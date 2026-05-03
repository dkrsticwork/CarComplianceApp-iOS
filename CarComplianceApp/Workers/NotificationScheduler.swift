import Foundation
import UserNotifications

final class NotificationScheduler {
    static let shared = NotificationScheduler()
    private init() {}

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func scheduleAll(tasks: [ComplianceTask], prefs: NotificationPreferences) {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        let today = Calendar.current.startOfDay(for: Date())

        for task in tasks where task.status != .done && task.status != .snoozed {
            guard let due = task.dueDate else { continue }
            let days = Calendar.current.dateComponents([.day], from: today, to: due).day ?? 0

            var shouldNotify = false
            if days < 0 {
                shouldNotify = true
            } else if days <= 1 && prefs.oneDay {
                shouldNotify = true
            } else if days <= 7 && prefs.sevenDays {
                shouldNotify = true
            } else if days <= 30 && prefs.thirtyDays {
                shouldNotify = true
            }

            guard shouldNotify else { continue }

            let content = UNMutableNotificationContent()
            content.title = "Car Compliance: \(task.title)"
            content.body = {
                if days < 0 { return "Overdue by \(-days) day\(-days == 1 ? "" : "s")" }
                if days == 0 { return "Due today" }
                if days == 1 { return "Due tomorrow" }
                return "Due in \(days) days"
            }()
            content.sound = .default

            // Fire ~10 seconds from now (notification centre shows it immediately on device)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
            let request = UNNotificationRequest(
                identifier: "task_\(task.id)",
                content: content,
                trigger: trigger
            )
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        }
    }
}
