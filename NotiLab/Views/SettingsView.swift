import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel

    @State private var showResetNames = false
    @State private var showResetTemplates = false
    @State private var showCancelAll = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    namesCard
                    optionsCard
                    aboutCard
                    resetCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 6)
                .padding(.bottom, 110)
            }
            .background(NLBackground())
            .navigationTitle("Ajustes")
            .navigationBarTitleDisplayMode(.large)
            .alert("Restaurar nombres", isPresented: $showResetNames) {
                Button("Restaurar", role: .destructive) { model.resetNames() }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Se recuperarán los nombres predeterminados de México y Argentina. Los nombres personalizados se quitarán.")
            }
            .alert("Restaurar plantillas", isPresented: $showResetTemplates) {
                Button("Restaurar", role: .destructive) { model.resetTemplates() }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Se recuperarán las seis plantillas originales. Las plantillas que hayas creado se quitarán.")
            }
            .alert("Cancelar notificaciones", isPresented: $showCancelAll) {
                Button("Cancelar todas", role: .destructive) {
                    Task { await model.cancelAll() }
                }
                Button("Volver", role: .cancel) {}
            } message: {
                Text("Se quitarán las \(model.pending.count) notificaciones pendientes.")
            }
        }
    }

    // MARK: - Names

    private var namesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(
                title: "Nombres",
                subtitle: "Elige de dónde salen los nombres que reemplazan el token {nombre}."
            )

            Picker("Región", selection: $model.names.region) {
                ForEach(NameRegion.allCases) { region in
                    Text(region.title).tag(region)
                }
            }
            .pickerStyle(.segmented)

            VStack(spacing: 14) {
                NavigationLink {
                    NameListEditor(title: "Nombres de México", names: $model.names.mexico)
                } label: {
                    SettingsRow(
                        icon: "flag.fill",
                        title: "Nombres de México",
                        detail: "\(model.names.mexico.count)",
                        tint: .nlAccent
                    )
                }

                Divider().opacity(0.45)

                NavigationLink {
                    NameListEditor(title: "Nombres de Argentina", names: $model.names.argentina)
                } label: {
                    SettingsRow(
                        icon: "flag.fill",
                        title: "Nombres de Argentina",
                        detail: "\(model.names.argentina.count)",
                        tint: .nlBlue
                    )
                }

                Divider().opacity(0.45)

                NavigationLink {
                    NameListEditor(title: "Nombres personalizados", names: $model.names.custom)
                } label: {
                    SettingsRow(
                        icon: "person.badge.plus",
                        title: "Nombres personalizados",
                        detail: "\(model.names.custom.count)",
                        tint: .nlPurple
                    )
                }
            }
            .buttonStyle(.plain)
        }
        .nlCard()
    }

    // MARK: - Options

    private var optionsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(
                title: "Notificaciones",
                subtitle: "Ajustes que se aplican a la próxima programación."
            )

            Toggle(isOn: $model.schedule.soundEnabled) {
                Label("Sonido al llegar", systemImage: "speaker.wave.2.fill")
                    .font(.subheadline)
            }
            .tint(.nlAccent)

            Divider().opacity(0.45)

            Toggle(isOn: $model.schedule.badgeEnabled) {
                Label("Badge en el icono", systemImage: "app.badge.fill")
                    .font(.subheadline)
            }
            .tint(.nlAccent)

            Divider().opacity(0.45)

            Toggle(isOn: $model.schedule.replaceExisting) {
                Label("Reemplazar programación anterior", systemImage: "arrow.triangle.2.circlepath")
                    .font(.subheadline)
            }
            .tint(.nlAccent)

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Los avisos se envían aunque cierres la app. iOS permite hasta 64 notificaciones pendientes por app; si programas más, se recortan a 64.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .nlCard()
    }

    // MARK: - About

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Acerca de NotiLab")

            HStack {
                SettingsRow(icon: "bell.badge.fill", title: "Versión", detail: versionText)
            }

            Divider().opacity(0.45)

            HStack {
                SettingsRow(
                    icon: model.authorizationIsReady ? "checkmark.circle.fill" : "exclamationmark.circle.fill",
                    title: "Permiso de notificaciones",
                    detail: model.authorizationStatus.displayName,
                    tint: model.authorizationIsReady ? .nlAccent : .nlOrange
                )
            }

            if !model.authorizationIsReady {
                Button {
                    model.openSystemSettings()
                } label: {
                    Label("Abrir Ajustes de iOS", systemImage: "gearshape.fill")
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .background(Color.nlAccent.opacity(0.12), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.nlAccent)
            }

            Divider().opacity(0.45)

            Text("NotiLab es una app de demostración y bromas. Los avisos llevan el nombre e icono de NotiLab y no suplantan a otras apps, marcas ni llamadas reales. No se envían datos a ningún servidor.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Link(destination: URL(string: "https://github.com/IrvinTovar/NotiLab")!) {
                SettingsRow(icon: "chevron.left.forwardslash.chevron.right", title: "Código en GitHub")
            }
        }
        .nlCard()
    }

    // MARK: - Reset

    private var resetCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Mantenimiento")

            Button {
                showResetNames = true
            } label: {
                SettingsRow(icon: "arrow.counterclockwise", title: "Restaurar nombres", tint: .nlOrange)
            }
            .buttonStyle(.plain)

            Divider().opacity(0.45)

            Button {
                showResetTemplates = true
            } label: {
                SettingsRow(icon: "square.stack.3d.up.fill", title: "Restaurar plantillas", tint: .nlOrange)
            }
            .buttonStyle(.plain)

            Divider().opacity(0.45)

            Button {
                showCancelAll = true
            } label: {
                SettingsRow(icon: "xmark.circle.fill", title: "Cancelar notificaciones pendientes", tint: .nlRed)
            }
            .buttonStyle(.plain)
            .disabled(model.pending.isEmpty)
            .opacity(model.pending.isEmpty ? 0.5 : 1)
        }
        .nlCard()
    }

    private var versionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }
}

// MARK: - Name editor

struct NameListEditor: View {
    @Binding var names: [String]

    let title: String

    @State private var newName = ""

    var body: some View {
        List {
            Section {
                ForEach(names, id: \.self) { name in
                    Text(name)
                        .font(.body)
                }
                .onDelete { offsets in
                    names.remove(atOffsets: offsets)
                }
            } header: {
                Text(names.count == 1 ? "1 nombre" : "\(names.count) nombres")
            } footer: {
                Text("El token {nombre} elegirá uno de estos nombres al azar.")
            }

            Section {
                HStack(spacing: 10) {
                    TextField("Agregar nombre", text: $newName)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                    Button {
                        addName()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Color.nlAccent)
                    }
                    .buttonStyle(.plain)
                    .disabled(trimmedNewName.isEmpty)
                }
            } header: {
                Text("Añadir")
            }
        }
        .scrollContentBackground(.hidden)
        .background(NLBackground())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            EditButton()
        }
    }

    private var trimmedNewName: String {
        newName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func addName() {
        let name = trimmedNewName
        guard !name.isEmpty else { return }
        guard !names.contains(where: { $0.caseInsensitiveCompare(name) == .orderedSame }) else {
            newName = ""
            return
        }
        withAnimation(.easeOut(duration: 0.2)) {
            names.append(name)
        }
        newName = ""
    }
}
