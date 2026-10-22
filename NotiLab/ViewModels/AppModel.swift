import Foundation
import SwiftUI
import UIKit
import UserNotifications

@MainActor
final class AppModel: ObservableObject {
    @Published var templates: [NotificationTemplate] {
        didSet { persistTemplates() }
    }

    @Published var names: NamesConfig {
        didSet { persistNames() }
    }

    @Published var schedule: ScheduleConfig {
        didSet { persistSchedule() }
    }

    @Published var selectedTemplateID: UUID {
        didSet { defaults.set(selectedTemplateID.uuidString, forKey: Keys.selectedTemplate) }
    }

    @Published var pending: [PendingNotification] = []
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var isBusy = false
    @Published var toast: String?
    @Published var errorMessage: String?

    private let service = NotificationService.shared
    private let defaults = UserDefaults.standard
    private let maxPending = 64

    private enum Keys {
        static let templates = "notilab.templates.v1"
        static let names = "notilab.names.v1"
        static let schedule = "notilab.schedule.v1"
        static let selectedTemplate = "notilab.selectedTemplate.v1"
    }

    init() {
        let loadedTemplates = Self.load([NotificationTemplate].self, key: Keys.templates)
            ?? NotificationTemplate.defaults
        let safeTemplates = loadedTemplates.isEmpty ? NotificationTemplate.defaults : loadedTemplates

        templates = safeTemplates
        names = Self.load(NamesConfig.self, key: Keys.names) ?? NamesConfig()
        schedule = Self.load(ScheduleConfig.self, key: Keys.schedule) ?? ScheduleConfig()

        let storedID = defaults.string(forKey: Keys.selectedTemplate)
            .flatMap(UUID.init(uuidString:))
        selectedTemplateID = safeTemplates.first(where: { $0.id == storedID })?.id
            ?? safeTemplates[0].id
    }

    var selectedTemplate: NotificationTemplate {
        templates.first(where: { $0.id == selectedTemplateID })
            ?? templates.first
            ?? NotificationTemplate.defaults[0]
    }

    var previewPayload: NotificationPayload {
        TokenResolver.resolve(
            template: selectedTemplate,
            names: names.activeNames,
            cities: names.activeCities,
            region: names.region
        )
    }

    var pendingLimit: Int { maxPending }

    var authorizationIsReady: Bool {
        authorizationStatus.canDeliverNotifications
    }

    func refresh() async {
        authorizationStatus = await service.refreshAuthorization()
        pending = await service.pending()
    }

    func requestAuthorization() async {
        authorizationStatus = await service.requestAuthorization()
        if authorizationStatus.canDeliverNotifications {
            showToast("Notificaciones activadas")
        } else if authorizationStatus == .denied {
            showToast("Actívalas desde Ajustes de iOS")
        }
    }

    func scheduleNow() async {
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }

        if authorizationStatus == .notDetermined {
            authorizationStatus = await service.requestAuthorization()
        }
        guard authorizationStatus.canDeliverNotifications else {
            errorMessage = NotificationError.notAuthorized.localizedDescription
            return
        }

        do {
            let count = try await service.schedule(
                config: schedule,
                template: selectedTemplate,
                names: names.activeNames,
                cities: names.activeCities,
                region: names.region
            )
            await refreshPending()
            showToast(count == 1 ? "1 notificación programada" : "\(count) notificaciones programadas")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func scheduleTest() async {
        if authorizationStatus == .notDetermined {
            authorizationStatus = await service.requestAuthorization()
        }
        guard authorizationStatus.canDeliverNotifications else {
            errorMessage = NotificationError.notAuthorized.localizedDescription
            return
        }

        do {
            try await service.scheduleTest(
                config: schedule,
                template: selectedTemplate,
                names: names.activeNames,
                cities: names.activeCities,
                region: names.region
            )
            await refreshPending()
            showToast("Prueba en 5 segundos")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func cancelAll() async {
        await service.cancelAll()
        pending = await service.pending()
        showToast("Notificaciones canceladas")
    }

    func refreshPending() async {
        pending = await service.pending()
    }

    func upsertTemplate(_ template: NotificationTemplate) {
        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            templates[index] = template
        } else {
            templates.append(template)
            selectedTemplateID = template.id
        }
    }

    func deleteTemplate(_ template: NotificationTemplate) {
        guard templates.count > 1 else { return }
        templates.removeAll { $0.id == template.id }
        if selectedTemplateID == template.id, let first = templates.first {
            selectedTemplateID = first.id
        }
    }

    func resetTemplates() {
        templates = NotificationTemplate.defaults
        selectedTemplateID = templates[0].id
        showToast("Plantillas restauradas")
    }

    func resetNames() {
        names = NamesConfig()
        showToast("Nombres restaurados")
    }

    func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    func showToast(_ message: String) {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
            toast = message
        }
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 2_400_000_000)
            guard let self, self.toast == message else { return }
            withAnimation(.easeOut(duration: 0.2)) {
                self.toast = nil
            }
        }
    }

    private func persistTemplates() {
        if let data = try? JSONEncoder().encode(templates) {
            defaults.set(data, forKey: Keys.templates)
        }
    }

    private func persistNames() {
        if let data = try? JSONEncoder().encode(names) {
            defaults.set(data, forKey: Keys.names)
        }
    }

    private func persistSchedule() {
        if let data = try? JSONEncoder().encode(schedule) {
            defaults.set(data, forKey: Keys.schedule)
        }
    }

    private static func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
