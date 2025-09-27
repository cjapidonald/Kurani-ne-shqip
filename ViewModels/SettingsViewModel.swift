import Foundation
import SwiftUI
import UserNotifications

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var toast: LocalizedStringKey?
    @Published var readingReminderEnabled: Bool
    @Published var readingReminderTime: Date
    @Published var verseOfDayEnabled: Bool
    @Published var verseOfDayTime: Date

    private let progressStore: ReadingProgressStore
    private let translationStore: TranslationStore
    private let notificationManager: NotificationManager
    private let defaults: UserDefaults

    private enum Keys {
        static let readingReminderEnabled = "settings.readingReminder.enabled"
        static let readingReminderTime = "settings.readingReminder.time"
        static let verseOfDayEnabled = "settings.verseOfDay.enabled"
        static let verseOfDayTime = "settings.verseOfDay.time"
    }

    init(
        progressStore: ReadingProgressStore,
        translationStore: TranslationStore,
        notificationManager: NotificationManager = .shared,
        defaults: UserDefaults = .standard
    ) {
        self.progressStore = progressStore
        self.translationStore = translationStore
        self.notificationManager = notificationManager
        self.defaults = defaults

        let storedTime = defaults.object(forKey: Keys.readingReminderTime) as? Date ?? Self.defaultReminderTime()
        readingReminderTime = storedTime
        readingReminderEnabled = defaults.object(forKey: Keys.readingReminderEnabled) as? Bool ?? false
        verseOfDayEnabled = defaults.object(forKey: Keys.verseOfDayEnabled) as? Bool ?? false
        let storedVerseTime = defaults.object(forKey: Keys.verseOfDayTime) as? Date ?? Self.defaultVerseOfDayTime()
        verseOfDayTime = storedVerseTime
    }

    func resetReadingProgress() {
        progressStore.reset()
        toast = LocalizedStringKey("settings.progress.resetSuccess")
    }

    func setReadingReminderEnabled(_ isOn: Bool) {
        Task { await handleReadingReminderToggle(isOn) }
    }

    func updateReadingReminderTime(_ newTime: Date) {
        readingReminderTime = newTime
        defaults.set(newTime, forKey: Keys.readingReminderTime)

        guard readingReminderEnabled else { return }

        Task {
            guard await ensureAuthorization() else {
                readingReminderEnabled = false
                defaults.set(false, forKey: Keys.readingReminderEnabled)
                toast = LocalizedStringKey("settings.notifications.permissionDenied")
                return
            }

            let scheduled = await scheduleReadingReminder()

            if scheduled {
                toast = LocalizedStringKey("settings.notifications.reminderTimeUpdated")
            } else {
                readingReminderEnabled = false
                defaults.set(false, forKey: Keys.readingReminderEnabled)
                toast = LocalizedStringKey("settings.notifications.error")
            }
        }
    }

    func setVerseOfDayEnabled(_ isOn: Bool) {
        Task { await handleVerseOfDayToggle(isOn) }
    }

    func updateVerseOfDayTime(_ newTime: Date) {
        verseOfDayTime = newTime
        defaults.set(newTime, forKey: Keys.verseOfDayTime)

        guard verseOfDayEnabled else { return }

        Task {
            guard await ensureAuthorization() else {
                verseOfDayEnabled = false
                defaults.set(false, forKey: Keys.verseOfDayEnabled)
                toast = LocalizedStringKey("settings.notifications.permissionDenied")
                return
            }

            switch await scheduleVerseOfDayNotifications() {
            case .success:
                defaults.set(true, forKey: Keys.verseOfDayEnabled)
                toast = LocalizedStringKey("settings.notifications.verseTimeUpdated")
            case .noVerses:
                await notificationManager.cancelVerseOfDay()
                verseOfDayEnabled = false
                defaults.set(false, forKey: Keys.verseOfDayEnabled)
                toast = LocalizedStringKey("settings.notifications.verseUnavailable")
            case .failure:
                await notificationManager.cancelVerseOfDay()
                verseOfDayEnabled = false
                defaults.set(false, forKey: Keys.verseOfDayEnabled)
                toast = LocalizedStringKey("settings.notifications.error")
            }
        }
    }

    // MARK: - Notification Scheduling

    private func handleReadingReminderToggle(_ isOn: Bool) async {
        if isOn {
            readingReminderEnabled = true

            guard await ensureAuthorization() else {
                readingReminderEnabled = false
                defaults.set(false, forKey: Keys.readingReminderEnabled)
                toast = LocalizedStringKey("settings.notifications.permissionDenied")
                return
            }

            let scheduled = await scheduleReadingReminder()
            guard scheduled else {
                readingReminderEnabled = false
                defaults.set(false, forKey: Keys.readingReminderEnabled)
                toast = LocalizedStringKey("settings.notifications.error")
                return
            }

            defaults.set(true, forKey: Keys.readingReminderEnabled)
            toast = LocalizedStringKey("settings.notifications.reminderEnabled")
        } else {
            readingReminderEnabled = false
            defaults.set(false, forKey: Keys.readingReminderEnabled)
            notificationManager.cancelReadingReminder()
            toast = LocalizedStringKey("settings.notifications.reminderDisabled")
        }
    }

    private func scheduleReadingReminder() async -> Bool {
        var components = Calendar.current.dateComponents([.hour, .minute], from: readingReminderTime)
        components.second = 0

        do {
            try await notificationManager.scheduleReadingReminder(at: components)
            return true
        } catch {
            print("Failed to schedule reading reminder", error)
            return false
        }
    }

    private func handleVerseOfDayToggle(_ isOn: Bool) async {
        if isOn {
            verseOfDayEnabled = true

            guard await ensureAuthorization() else {
                verseOfDayEnabled = false
                defaults.set(false, forKey: Keys.verseOfDayEnabled)
                toast = LocalizedStringKey("settings.notifications.permissionDenied")
                return
            }

            switch await scheduleVerseOfDayNotifications() {
            case .success:
                defaults.set(true, forKey: Keys.verseOfDayEnabled)
                toast = LocalizedStringKey("settings.notifications.verseEnabled")
            case .noVerses:
                verseOfDayEnabled = false
                defaults.set(false, forKey: Keys.verseOfDayEnabled)
                toast = LocalizedStringKey("settings.notifications.verseUnavailable")
            case .failure:
                verseOfDayEnabled = false
                defaults.set(false, forKey: Keys.verseOfDayEnabled)
                toast = LocalizedStringKey("settings.notifications.error")
            }
        } else {
            verseOfDayEnabled = false
            defaults.set(false, forKey: Keys.verseOfDayEnabled)
            await notificationManager.cancelVerseOfDay()
            toast = LocalizedStringKey("settings.notifications.verseDisabled")
        }
    }

    private enum VerseSchedulingResult {
        case success
        case noVerses
        case failure
    }

    private func scheduleVerseOfDayNotifications() async -> VerseSchedulingResult {
        let verses = translationStore.randomAyahs(count: 30)
        guard !verses.isEmpty else { return .noVerses }

        let verseComponents = Calendar.current.dateComponents([.hour, .minute], from: verseOfDayTime)
        let hour = verseComponents.hour ?? 7
        let minute = verseComponents.minute ?? 0

        guard let firstFireDate = Calendar.current.nextDate(
            after: Date(),
            matching: DateComponents(hour: hour, minute: minute),
            matchingPolicy: .nextTime,
            direction: .forward
        ) else {
            return .failure
        }

        var notifications: [(DateComponents, String)] = []
        let calendar = Calendar.current
        let bodyFormat = NSLocalizedString(
            "notification.verseOfDay.body",
            comment: "Verse of the day body format"
        )

        for (index, entry) in verses.enumerated() {
            guard let fireDate = calendar.date(byAdding: .day, value: index, to: firstFireDate) else { continue }
            var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
            components.second = 0

            let surahName = translationStore.title(for: entry.surah)
            let body = String(
                format: bodyFormat,
                locale: Locale.current,
                entry.ayah.text,
                surahName,
                entry.ayah.number
            )
            notifications.append((components, body))
        }

        guard !notifications.isEmpty else { return .failure }

        do {
            try await notificationManager.scheduleVerseOfDayNotifications(notifications)
            return .success
        } catch {
            print("Failed to schedule verse of the day notifications", error)
            return .failure
        }
    }

#if DEBUG
    func runArabicAlbanianScopeCheck() {
        Task { await performArabicAlbanianScopeCheck() }
    }

    private func performArabicAlbanianScopeCheck() async {
        await translationStore.loadInitialData()

        let scopes: [(surah: Int, range: ClosedRange<Int>)] = [
            (1, 1...7),
            (2, 1...5)
        ]

        var encounteredError = false

        for (surah, range) in scopes {
            await translationStore.ensureArabicText(for: surah, ayahRange: range)

            for ayahNumber in range {
                do {
                    let words = try await translationStore.translationWords(for: surah, ayah: ayahNumber)
                    let albanianWordCount = words.filter { !$0.albanianWord.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
                    let arabicWordCount = words.filter { !$0.arabicWord.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count

                    let ayah = translationStore.ayahs(for: surah).first(where: { $0.number == ayahNumber })
                    let albanianTextWordCount = wordCount(for: ayah?.text ?? "")
                    let arabicTextWordCount = wordCount(for: ayah?.arabicText ?? "")

                    let albanianTextSummary = albanianTextWordCount > 0 ? "\(albanianTextWordCount)" : "missing"
                    let arabicTextSummary = arabicTextWordCount > 0 ? "\(arabicTextWordCount)" : "missing"

                    let summary = "ScopeCheck S\(surah):\(ayahNumber) AL words:\(albanianWordCount) text:\(albanianTextSummary) | AR words:\(arabicWordCount) text:\(arabicTextSummary)"
                    print(summary)
                } catch {
                    encounteredError = true
                    let message = "ScopeCheck S\(surah):\(ayahNumber) error: \(error.localizedDescription)"
                    print(message)
                }
            }
        }

        let toastMessage = encounteredError
            ? "Scope check completed with issues. See console."
            : "Scope check complete. See console."
        toast = LocalizedStringKey(stringLiteral: toastMessage)
    }

    private func wordCount(for text: String) -> Int {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return 0 }
        return trimmed.split(whereSeparator: { $0.isWhitespace }).count
    }
#endif

    private func ensureAuthorization() async -> Bool {
        let status = await notificationManager.authorizationStatus()
        switch status {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return await notificationManager.requestAuthorization()
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    private static func defaultReminderTime() -> Date {
        let calendar = Calendar.current
        let now = Date()
        return calendar.date(bySettingHour: 20, minute: 0, second: 0, of: now) ?? now
    }

    private static func defaultVerseOfDayTime() -> Date {
        let calendar = Calendar.current
        let now = Date()
        return calendar.date(bySettingHour: 7, minute: 0, second: 0, of: now) ?? now
    }
}
