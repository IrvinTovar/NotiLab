import Foundation
import UserNotifications

enum NotificationError: LocalizedError {
    case notAuthorized

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Activa las notificaciones para NotiLab desde Ajustes y vuelve a intentarlo."
        }
    }
}

@MainActor
final class NotificationService: ObservableObject {
    static let shared = NotificationService()

    private let center = UNUserNotificationCenter.current()
    private let prefix = "notilab.demo."
    private let maxPending = 64

    func refreshAuthorization() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }

    func requestAuthorization() async -> UNAuthorizationStatus {
        do {
            _ = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            // The system status below is the source of truth.
        }
        return await refreshAuthorization()
    }

    @discardableResult
    func schedule(
        config: ScheduleConfig,
        template: NotificationTemplate,
        names: [String],
        cities: [String],
        region: NameRegion
    ) async throws -> Int {
        let status = await refreshAuthorization()
        guard status.canDeliverNotifications else {
            throw NotificationError.notAuthorized
        }

        if config.replaceExisting {
            await cancelAll()
        }

        let count = min(max(config.count, 1), maxPending)
        let window = TimeInterval(max(config.window.seconds, 1))
        let delay = TimeInterval(max(config.delay.seconds, 0))
        let offsets = makeOffsets(count: count, window: window, distribution: config.distribution)
        let attachmentURL = TemplateImageStore.shared.attachmentURL(for: template)

        var scheduled = 0
        for (index, offset) in offsets.enumerated() {
            let payload = TokenResolver.resolve(
                template: template,
                names: names,
                cities: cities,
                region: region
            )

            let content = UNMutableNotificationContent()
            content.title = payload.title
            content.body = payload.body
            if config.soundEnabled {
                content.sound = .default
            }
            if config.badgeEnabled {
                content.badge = NSNumber(value: index + 1)
            }
            content.threadIdentifier = "notilab.\(template.id.uuidString)"
            content.userInfo = [
                "demo": true,
                "template": template.name
            ]
            if let attachmentURL,
               let attachment = makeAttachment(from: attachmentURL) {
                content.attachments = [attachment]
            }

            let interval = max(1, delay + offset)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
            let request = UNNotificationRequest(
                identifier: "\(prefix)\(UUID().uuidString)",
                content: content,
                trigger: trigger
            )
            try await center.add(request)
            scheduled += 1
        }

        return scheduled
    }

    func scheduleTest(
        config: ScheduleConfig,
        template: NotificationTemplate,
        names: [String],
        cities: [String],
        region: NameRegion
    ) async throws {
        let status = await refreshAuthorization()
        guard status.canDeliverNotifications else {
            throw NotificationError.notAuthorized
        }

        let payload = TokenResolver.resolve(
            template: template,
            names: names,
            cities: cities,
            region: region
        )

        let content = UNMutableNotificationContent()
        content.title = payload.title
        content.body = payload.body
        if config.soundEnabled {
            content.sound = .default
        }
        content.threadIdentifier = "notilab.test"
        content.userInfo = ["demo": true, "template": template.name]
        if let attachmentURL = TemplateImageStore.shared.attachmentURL(for: template),
           let attachment = makeAttachment(from: attachmentURL) {
            content.attachments = [attachment]
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(
            identifier: "\(prefix)test.\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        try await center.add(request)
    }

    func pending() async -> [PendingNotification] {
        let requests = await center.pendingNotificationRequests()
        return requests
            .filter { $0.identifier.hasPrefix(prefix) }
            .compactMap { request -> PendingNotification? in
                guard let date = nextDate(for: request.trigger) else { return nil }
                return PendingNotification(
                    id: request.identifier,
                    title: request.content.title,
                    body: request.content.body,
                    date: date,
                    templateName: request.content.userInfo["template"] as? String ?? "Notificación"
                )
            }
            .sorted { $0.date < $1.date }
    }

    func cancelAll() async {
        let requests = await center.pendingNotificationRequests()
        let ids = requests.map(\.identifier).filter { $0.hasPrefix(prefix) }
        guard !ids.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: ids)
        center.removeDeliveredNotifications(withIdentifiers: ids)
    }

    private func makeOffsets(
        count: Int,
        window: TimeInterval,
        distribution: Distribution
    ) -> [TimeInterval] {
        guard count > 0 else { return [] }
        guard count > 1 else { return [window / 2] }

        switch distribution {
        case .uniform:
            return (1...count).map { index in
                window * Double(index) / Double(count + 1)
            }
        case .random:
            let bucket = window / Double(count)
            return (0..<count).map { index in
                let start = bucket * Double(index)
                let end = bucket * Double(index + 1)
                return Double.random(in: start..<end)
            }
            .sorted()
        }
    }

    private func makeAttachment(from sourceURL: URL) -> UNNotificationAttachment? {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("NotiLabAttachments", isDirectory: true)
        try? FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        let fileExtension = sourceURL.pathExtension.isEmpty ? "png" : sourceURL.pathExtension
        let destination = directory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(fileExtension)

        do {
            try FileManager.default.copyItem(at: sourceURL, to: destination)
            return try UNNotificationAttachment(
                identifier: "notilab.thumbnail",
                url: destination,
                options: nil
            )
        } catch {
            return nil
        }
    }

    private func nextDate(for trigger: UNNotificationTrigger?) -> Date? {
        if let trigger = trigger as? UNTimeIntervalNotificationTrigger {
            return trigger.nextTriggerDate()
        }
        if let trigger = trigger as? UNCalendarNotificationTrigger {
            return trigger.nextTriggerDate()
        }
        return nil
    }
}

extension UNAuthorizationStatus {
    var canDeliverNotifications: Bool {
        switch self {
        case .authorized, .provisional, .ephemeral:
            return true
        default:
            return false
        }
    }

    var displayName: String {
        switch self {
        case .authorized, .provisional, .ephemeral:
            return "Activadas"
        case .denied:
            return "Desactivadas"
        case .notDetermined:
            return "Sin configurar"
        @unknown default:
            return "Desconocido"
        }
    }
}
