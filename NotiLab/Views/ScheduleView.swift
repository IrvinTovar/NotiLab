import SwiftUI

struct ScheduleView: View {
    @EnvironmentObject private var model: AppModel

    @State private var showTemplatePicker = false
    @State private var showCancelConfirmation = false

    private var template: NotificationTemplate { model.selectedTemplate }
    private var preview: NotificationPayload { model.previewPayload }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    heroCard
                    permissionCard
                    schedulingCard
                    previewCard
                    primaryButton
                    if !model.pending.isEmpty {
                        pendingCard
                    }
                    disclaimer
                }
                .padding(.horizontal, 20)
                .padding(.top, 6)
                .padding(.bottom, 110)
            }
            .background(NLBackground())
            .navigationTitle("NotiLab")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await model.scheduleTest() }
                    } label: {
                        Image(systemName: "paperplane.fill")
                    }
                    .accessibilityLabel("Enviar notificación de prueba")
                }
            }
            .sheet(isPresented: $showTemplatePicker) {
                TemplatePickerSheet(selectedID: $model.selectedTemplateID)
                    .environmentObject(model)
            }
            .alert("Cancelar notificaciones", isPresented: $showCancelConfirmation) {
                Button("Cancelar todas", role: .destructive) {
                    Task { await model.cancelAll() }
                }
                Button("Volver", role: .cancel) {}
            } message: {
                Text("Se quitarán las \(model.pending.count) notificaciones pendientes. Las que ya se entregaron no se pueden recuperar.")
            }
        }
    }

    // MARK: - Hero

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                IconBadge(icon: "bell.badge.fill", tint: .nlAccent, size: 50)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Notificaciones de demostración")
                        .font(.title3.weight(.bold))
                    Text("Programa avisos locales con nombres, textos y tiempos a tu gusto.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 7) {
                TagPill("100% local", icon: "iphone")
                TagPill("Nombres MX + AR", icon: "person.2.fill")
                TagPill("Máx. 64", icon: "clock.fill")
            }
        }
        .nlCard()
    }

    // MARK: - Permission

    @ViewBuilder
    private var permissionCard: some View {
        if !model.authorizationIsReady {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: model.authorizationStatus == .denied ? "bell.slash.fill" : "bell.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(model.authorizationStatus == .denied ? Color.nlOrange : Color.nlAccent)
                    .frame(width: 38, height: 38)
                    .background(
                        (model.authorizationStatus == .denied ? Color.nlOrange : Color.nlAccent).opacity(0.12),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(model.authorizationStatus == .denied ? "Notificaciones desactivadas" : "Activa las notificaciones")
                        .font(.subheadline.weight(.semibold))
                    Text(model.authorizationStatus == .denied
                         ? "Ábrelas desde Ajustes para que los avisos puedan llegar."
                         : "NotiLab necesita permiso para mostrar los avisos programados.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 6)

                Button {
                    if model.authorizationStatus == .denied {
                        model.openSystemSettings()
                    } else {
                        Task { await model.requestAuthorization() }
                    }
                } label: {
                    Text(model.authorizationStatus == .denied ? "Ajustes" : "Permitir")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(Color.nlAccent, in: Capsule())
                        .foregroundStyle(Color.nlInk)
                }
                .buttonStyle(.plain)
            }
            .nlCard(padding: 14)
        }
    }

    // MARK: - Scheduling

    private var schedulingCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                title: "Programación",
                subtitle: "Elige la plantilla, cuántas notificaciones quieres y durante cuánto tiempo."
            )

            Button {
                showTemplatePicker = true
            } label: {
                HStack(spacing: 12) {
                    IconBadge(icon: template.icon, tint: template.tint.color, size: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(template.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text(template.title.isEmpty ? "Sin título" : template.title)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Divider().opacity(0.5)

            ValueStepper(
                title: "Cantidad",
                subtitle: "Avisos que se van a programar.",
                value: $model.schedule.count,
                range: 1...model.pendingLimit,
                step: 1,
                display: { "\($0)" }
            )

            ValueStepper(
                title: "Durante",
                subtitle: "Ventana de tiempo para repartirlos.",
                value: $model.schedule.windowMinutes,
                range: 1...720,
                step: 5,
                display: { DurationText.minutes($0) }
            )

            ValueStepper(
                title: "Empezar en",
                subtitle: "Tiempo antes del primer aviso.",
                value: $model.schedule.delayMinutes,
                range: 0...120,
                step: 1,
                display: { $0 == 0 ? "Ahora" : "+\(DurationText.minutes($0))" }
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("Distribución")
                    .font(.subheadline.weight(.medium))
                Picker("Distribución", selection: $model.schedule.distribution) {
                    ForEach(Distribution.allCases) { distribution in
                        Text(distribution.title).tag(distribution)
                    }
                }
                .pickerStyle(.segmented)
            }

            Toggle(isOn: $model.schedule.soundEnabled) {
                Label("Sonido", systemImage: "speaker.wave.2.fill")
                    .font(.subheadline)
            }
            .tint(.nlAccent)

            Toggle(isOn: $model.schedule.badgeEnabled) {
                Label("Badge en el icono", systemImage: "app.badge.fill")
                    .font(.subheadline)
            }
            .tint(.nlAccent)

            Toggle(isOn: $model.schedule.replaceExisting) {
                Label("Reemplazar programación anterior", systemImage: "arrow.triangle.2.circlepath")
                    .font(.subheadline)
            }
            .tint(.nlAccent)

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Los avisos se envían aunque cierres la app. iOS permite hasta 64 notificaciones pendientes por app.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .nlCard()
    }

    // MARK: - Preview

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Vista previa", subtitle: "Así se verá el aviso en tu iPhone.")

            NotificationPreview(
                template: template,
                payload: preview,
                timeLabel: "ahora"
            )

            HStack {
                Button {
                    Task { await model.scheduleTest() }
                } label: {
                    Label("Probar en 5 s", systemImage: "play.fill")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.primary.opacity(0.07), in: Capsule())
                }
                .buttonStyle(.plain)

                Spacer()

                Text(template.name)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .nlCard()
    }

    // MARK: - CTA

    private var primaryButton: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                Task { await model.scheduleNow() }
            } label: {
                HStack(spacing: 10) {
                    if model.isBusy {
                        ProgressView()
                            .tint(Color.nlInk)
                    } else {
                        Image(systemName: "bell.badge.fill")
                    }

                    Text(model.schedule.count == 1
                         ? "Programar 1 notificación"
                         : "Programar \(model.schedule.count) notificaciones")
                        .font(.headline)

                    Spacer()

                    Image(systemName: "arrow.right")
                        .font(.subheadline.weight(.bold))
                }
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(
                    LinearGradient(
                        colors: [Color.nlAccent2, Color.nlAccentDeep],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 19, style: .continuous)
                )
                .foregroundStyle(Color.nlInk)
                .shadow(color: Color.nlAccent.opacity(0.25), radius: 16, y: 8)
            }
            .buttonStyle(.plain)
            .disabled(model.isBusy)

            Text("Se enviarán entre ahora y dentro de \(DurationText.minutes(model.schedule.delayMinutes + model.schedule.windowMinutes)).")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
        }
    }

    // MARK: - Pending

    private var pendingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                SectionHeader(
                    title: "Programadas",
                    subtitle: model.pending.count == 1 ? "1 aviso pendiente" : "\(model.pending.count) avisos pendientes"
                )
                Spacer()
                Button("Cancelar") {
                    showCancelConfirmation = true
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.nlRed)
                .padding(.top, 2)
            }

            ForEach(Array(model.pending.prefix(3))) { item in
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(template.tint.color.opacity(0.14))
                        .frame(width: 36, height: 36)
                        .overlay {
                            Image(systemName: template.icon)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(template.tint.color)
                        }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                            .font(.subheadline.weight(.medium))
                            .lineLimit(1)
                        Text(DurationText.short(item.date))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text(item.date, style: .relative)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            if model.pending.count > 3 {
                Text("+ \(model.pending.count - 3) más")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .nlCard()
    }

    // MARK: - Disclaimer

    private var disclaimer: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "checkmark.shield.fill")
                .font(.caption)
                .foregroundStyle(Color.nlAccent)
            Text("NotiLab es una app de demostración y bromas. Los avisos llevan el nombre e icono de NotiLab y no suplantan a otras apps, marcas ni llamadas reales. Todo se programa en tu iPhone.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Value stepper

struct ValueStepper: View {
    let title: String
    let subtitle: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    let display: (Int) -> String

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            HStack(spacing: 0) {
                Button {
                    value = max(range.lowerBound, value - step)
                } label: {
                    Image(systemName: "minus")
                        .font(.caption.weight(.bold))
                        .frame(width: 34, height: 34)
                }
                .disabled(value <= range.lowerBound)

                Text(display(value))
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .frame(minWidth: 58)
                    .contentTransition(.numericText())

                Button {
                    value = min(range.upperBound, value + step)
                } label: {
                    Image(systemName: "plus")
                        .font(.caption.weight(.bold))
                        .frame(width: 34, height: 34)
                }
                .disabled(value >= range.upperBound)
            }
            .foregroundStyle(.primary)
            .background(Color.primary.opacity(0.07), in: Capsule())
            .buttonStyle(.plain)
        }
    }
}
