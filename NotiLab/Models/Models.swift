import Foundation
import SwiftUI

// MARK: - Templates

enum TemplateTint: String, Codable, CaseIterable, Identifiable {
    case green
    case blue
    case teal
    case orange
    case purple
    case pink
    case red
    case gray

    var id: String { rawValue }

    var title: String {
        switch self {
        case .green: return "Verde"
        case .blue: return "Azul"
        case .teal: return "Turquesa"
        case .orange: return "Naranja"
        case .purple: return "Morado"
        case .pink: return "Rosa"
        case .red: return "Rojo"
        case .gray: return "Gris"
        }
    }

    var color: Color {
        switch self {
        case .green: return .nlAccent
        case .blue: return .nlBlue
        case .teal: return .nlTeal
        case .orange: return .nlOrange
        case .purple: return .nlPurple
        case .pink: return .nlPink
        case .red: return .nlRed
        case .gray: return .nlGray
        }
    }
}

struct NotificationTemplate: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var icon: String
    var tint: TemplateTint
    var title: String
    var body: String

    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        tint: TemplateTint,
        title: String,
        body: String
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.tint = tint
        self.title = title
        self.body = body
    }

    static let blank = NotificationTemplate(
        name: "",
        icon: "bell.badge.fill",
        tint: .green,
        title: "",
        body: ""
    )

    static let defaults: [NotificationTemplate] = [
        NotificationTemplate(
            name: "Pedido nuevo",
            icon: "bag.fill",
            tint: .green,
            title: "Nuevo pedido",
            body: "{nombre} acaba de hacer un pedido en tu tienda."
        ),
        NotificationTemplate(
            name: "Pago recibido",
            icon: "creditcard.fill",
            tint: .blue,
            title: "Pago recibido",
            body: "Recibiste un pago de {nombre}."
        ),
        NotificationTemplate(
            name: "Llamada perdida",
            icon: "phone.down.fill",
            tint: .red,
            title: "Llamada perdida",
            body: "{nombre} · hace 2 min"
        ),
        NotificationTemplate(
            name: "Mensaje nuevo",
            icon: "message.fill",
            tint: .teal,
            title: "{nombre}",
            body: "Oye, ¿sigues por ahí?"
        ),
        NotificationTemplate(
            name: "Envío en camino",
            icon: "shippingbox.fill",
            tint: .orange,
            title: "Tu pedido está en camino",
            body: "El paquete de {nombre} llegará hoy."
        ),
        NotificationTemplate(
            name: "Recordatorio",
            icon: "bell.badge.fill",
            tint: .purple,
            title: "Recordatorio",
            body: "Revisa los pedidos pendientes de hoy."
        )
    ]
}

enum TemplateIcon {
    static let all: [String] = [
        "bell.badge.fill",
        "bell.fill",
        "bag.fill",
        "cart.fill",
        "creditcard.fill",
        "banknote.fill",
        "shippingbox.fill",
        "truck.box.fill",
        "phone.down.fill",
        "phone.fill",
        "message.fill",
        "envelope.fill",
        "calendar.badge.clock",
        "gift.fill",
        "heart.fill",
        "star.fill",
        "person.crop.circle.fill",
        "sparkles"
    ]
}

// MARK: - Names

enum NameRegion: String, Codable, CaseIterable, Identifiable {
    case mexico
    case argentina
    case mixta

    var id: String { rawValue }

    var title: String {
        switch self {
        case .mexico: return "México"
        case .argentina: return "Argentina"
        case .mixta: return "Mixto"
        }
    }
}

struct NamesConfig: Codable, Equatable {
    var mexico: [String] = NamesConfig.defaultMexico
    var argentina: [String] = NamesConfig.defaultArgentina
    var custom: [String] = []
    var region: NameRegion = .mixta

    var activeNames: [String] {
        let source: [String]
        switch region {
        case .mexico:
            source = mexico
        case .argentina:
            source = argentina
        case .mixta:
            source = mexico + argentina
        }
        let allNames = source + custom
        return allNames.isEmpty ? ["Cliente"] : allNames
    }

    var activeCities: [String] {
        switch region {
        case .mexico: return NamesConfig.citiesMexico
        case .argentina: return NamesConfig.citiesArgentina
        case .mixta: return NamesConfig.citiesMexico + NamesConfig.citiesArgentina
        }
    }

    static let defaultMexico: [String] = [
        "Ana Sofía Hernández",
        "Luis Miguel García",
        "Mariana López",
        "José Antonio Martínez",
        "Fernanda Ruiz",
        "Diego Sánchez",
        "Valeria Torres",
        "Emiliano Ramírez",
        "Camila Flores",
        "Santiago Gómez",
        "Ximena Morales",
        "Mateo Castillo",
        "Regina Ortiz",
        "Sebastián Mendoza",
        "Renata Vargas",
        "Alejandro Cruz",
        "Daniela Reyes",
        "Andrés Jiménez",
        "Paola Navarro",
        "Ricardo Salazar",
        "Montserrat Domínguez",
        "Iván Guerrero",
        "Natalia Ríos",
        "Héctor Aguilar"
    ]

    static let defaultArgentina: [String] = [
        "Martina Fernández",
        "Joaquín Rodríguez",
        "Sofía González",
        "Mateo López",
        "Valentina Martínez",
        "Benjamín Pérez",
        "Catalina Romero",
        "Thiago Álvarez",
        "Julieta Díaz",
        "Lautaro Sosa",
        "Mía Herrera",
        "Tomás Acosta",
        "Emma Benítez",
        "Bautista Medina",
        "Delfina Suárez",
        "Franco Giménez",
        "Isabella Rojas",
        "Santino Cabrera",
        "Micaela Godoy",
        "Gonzalo Ferreyra",
        "Abril Quiroga",
        "Nicolás Ledesma",
        "Sol Paredes",
        "Facundo Vera"
    ]

    static let citiesMexico: [String] = [
        "CDMX", "Guadalajara", "Monterrey", "Puebla",
        "Mérida", "Querétaro", "Tijuana", "León"
    ]

    static let citiesArgentina: [String] = [
        "Buenos Aires", "Córdoba", "Rosario", "Mendoza",
        "La Plata", "Salta", "Mar del Plata", "Neuquén"
    ]
}

// MARK: - Scheduling

enum Distribution: String, Codable, CaseIterable, Identifiable {
    case random
    case uniform

    var id: String { rawValue }

    var title: String {
        switch self {
        case .random: return "Aleatorio"
        case .uniform: return "Uniforme"
        }
    }

    var subtitle: String {
        switch self {
        case .random: return "Sin hora fija"
        case .uniform: return "Repartido"
        }
    }
}

struct ScheduleConfig: Codable, Equatable {
    var count: Int = 6
    var windowMinutes: Int = 120
    var delayMinutes: Int = 1
    var distribution: Distribution = .random
    var soundEnabled: Bool = true
    var badgeEnabled: Bool = false
    var replaceExisting: Bool = true
}

// MARK: - Resolved payload

struct NotificationPayload: Equatable {
    let title: String
    let body: String
}

enum TokenResolver {
    static func resolve(
        template: NotificationTemplate,
        names: [String],
        cities: [String],
        region: NameRegion
    ) -> NotificationPayload {
        let name = names.randomElement() ?? "Cliente"
        let city = cities.randomElement() ?? "tu ciudad"
        let amount = Int.random(in: 2...95) * 100
        let currency = region == .argentina ? "ARS" : "MXN"

        func expand(_ text: String) -> String {
            text
                .replacingOccurrences(of: "{nombre}", with: name)
                .replacingOccurrences(of: "{ciudad}", with: city)
                .replacingOccurrences(of: "{monto}", with: "$\(amount.formatted()) \(currency)")
        }

        let resolvedTitle = expand(template.title).trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedBody = expand(template.body).trimmingCharacters(in: .whitespacesAndNewlines)

        return NotificationPayload(
            title: resolvedTitle.isEmpty ? template.name : resolvedTitle,
            body: resolvedBody.isEmpty ? "Notificación de demostración." : resolvedBody
        )
    }
}

// MARK: - Pending

struct PendingNotification: Identifiable, Equatable {
    let id: String
    let title: String
    let body: String
    let date: Date
    let templateName: String
}
