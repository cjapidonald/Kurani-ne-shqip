import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()

    private init() {}

    func authorizationStatus() async -> UNAuthorizationStatus {
        await withCheckedContinuation { continuation in
            center.getNotificationSettings { settings in
                continuation.resume(returning: settings.authorizationStatus)
            }
        }
    }

    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            print("Failed to request notification authorization", error)
            return false
        }
    }

    func scheduleReadingReminder(at components: DateComponents) async throws {
        var dateComponents = components
        dateComponents.second = 0
        cancelReadingReminder()

        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("notification.readingReminder.title", comment: "Reading reminder title")
        content.body = NSLocalizedString("notification.readingReminder.body", comment: "Reading reminder body")
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: Self.readingReminderIdentifier,
            content: content,
            trigger: trigger
        )

        try await add(request)
    }

    func cancelReadingReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [Self.readingReminderIdentifier])
    }

    func scheduleVerseOfDayNotifications(_ notifications: [(DateComponents, String)]) async throws {
        await cancelVerseOfDay()

        for (index, entry) in notifications.enumerated() {
            var components = entry.0
            components.second = 0

            let content = UNMutableNotificationContent()
            content.title = NSLocalizedString("notification.verseOfDay.title", comment: "Verse of the day title")
            content.body = entry.1
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: "\(Self.verseOfDayIdentifierPrefix).\(index)",
                content: content,
                trigger: trigger
            )

            try await add(request)
        }
    }

    func cancelVerseOfDay() async {
        let identifiers = await verseOfDayPendingIdentifiers()
        guard !identifiers.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    // MARK: - Helpers

    private func verseOfDayPendingIdentifiers() async -> [String] {
        await withCheckedContinuation { continuation in
            center.getPendingNotificationRequests { requests in
                let identifiers = requests
                    .map(\.identifier)
                    .filter { $0.hasPrefix(Self.verseOfDayIdentifierPrefix) }
                continuation.resume(returning: identifiers)
            }
        }
    }

    private func add(_ request: UNNotificationRequest) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            center.add(request) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    private static let readingReminderIdentifier = "com.kurani.notifications.readingReminder"
    private static let verseOfDayIdentifierPrefix = "com.kurani.notifications.verseOfDay"
}

