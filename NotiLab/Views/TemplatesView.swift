import SwiftUI
import PhotosUI
import UIKit

struct TemplatesView: View {
    @EnvironmentObject private var model: AppModel
    @Binding var selectedTab: AppTab

    @State private var editingTemplate: NotificationTemplate?
    @State private var isCreating = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Crea avisos para una demo, una broma o tus propias pruebas. Puedes cambiar el icono, el color, el título, el mensaje y los nombres.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    ForEach(model.templates) { template in
                        TemplateCard(
                            template: template,
                            isSelected: template.id == model.selectedTemplateID,
                            onUse: {
                                model.selectedTemplateID = template.id
                                selectedTab = .schedule
                            },
                            onEdit: {
                                editingTemplate = template
                            },
                            onDelete: model.templates.count > 1 ? {
                                model.deleteTemplate(template)
                            } : nil
                        )
                    }

                    Button {
                        isCreating = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 19, weight: .semibold))
                            Text("Nueva plantilla")
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 54)
                        .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6, 5]))
                                .foregroundStyle(Color.primary.opacity(0.13))
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 6)
                .padding(.bottom, 110)
            }
            .background(NLBackground())
            .navigationTitle("Plantillas")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isCreating = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Nueva plantilla")
                }
            }
            .sheet(item: $editingTemplate) { template in
                TemplateEditorView(template: template, isNew: false)
                    .environmentObject(model)
            }
            .sheet(isPresented: $isCreating) {
                TemplateEditorView(template: .blank, isNew: true)
                    .environmentObject(model)
            }
        }
    }
}

// MARK: - Card

struct TemplateCard: View {
    let template: NotificationTemplate
    let isSelected: Bool
    let onUse: () -> Void
    let onEdit: () -> Void
    let onDelete: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                TemplateIconView(template: template, size: 42)

                VStack(alignment: .leading, spacing: 2) {
                    Text(template.name)
                        .font(.headline)
                    Text(template.title.isEmpty ? "Sin título" : template.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(Color.nlAccent)
                }
            }

            Text(template.body.isEmpty ? "Sin mensaje" : template.body)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                if template.title.contains("{") || template.body.contains("{") {
                    TagPill("Variables", icon: "sparkles")
                }
                Spacer()
                Button(action: onUse) {
                    Text(isSelected ? "En uso" : "Usar")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 13)
                        .padding(.vertical, 7)
                        .background(isSelected ? Color.nlAccent.opacity(0.16) : Color.nlAccent, in: Capsule())
                        .foregroundStyle(isSelected ? Color.nlAccent : Color.nlInk)
                }
                .buttonStyle(.plain)
            }
        }
        .nlCard()
        .contentShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .onTapGesture(perform: onEdit)
        .contextMenu {
            Button {
                onEdit()
            } label: {
                Label("Editar", systemImage: "pencil")
            }
            if let onDelete {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Eliminar", systemImage: "trash")
                }
            }
        }
    }
}

// MARK: - Picker

struct TemplatePickerSheet: View {
    @EnvironmentObject private var model: AppModel
    @Binding var selectedID: UUID
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(model.templates) { template in
                    Button {
                        selectedID = template.id
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            TemplateIconView(template: template, size: 38)
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
                            if template.id == selectedID {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.nlAccent)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .scrollContentBackground(.hidden)
            .background(NLBackground())
            .navigationTitle("Elegir plantilla")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { dismiss() }
                        .font(.subheadline.weight(.semibold))
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Editor

struct TemplateEditorView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss

    @State private var draft: NotificationTemplate
    @State private var showDeleteAlert = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isImportingImage = false

    private let isNew: Bool
    private let originalImageName: String?

    init(template: NotificationTemplate, isNew: Bool) {
        _draft = State(initialValue: template)
        self.isNew = isNew
        self.originalImageName = template.imageName
    }

    private var preview: NotificationPayload {
        TokenResolver.resolve(
            template: draft,
            names: model.names.activeNames,
            cities: model.names.activeCities,
            region: model.names.region
        )
    }

    private var canDelete: Bool {
        !isNew && model.templates.count > 1
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    nameField
                    imageSection
                    presetPicker
                    iconPicker
                    tintPicker
                    titleField
                    bodyEditor
                    tokenRow
                    previewCard
                    if canDelete { deleteButton }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 60)
            }
            .background(NLBackground())
            .navigationTitle(isNew ? "Nueva plantilla" : "Editar plantilla")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Guardar") { save() }
                        .fontWeight(.semibold)
                        .disabled(draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Listo") { nlHideKeyboard() }
                }
            }
            .alert("Eliminar plantilla", isPresented: $showDeleteAlert) {
                Button("Eliminar", role: .destructive) {
                    TemplateImageStore.shared.delete(named: originalImageName)
                    model.deleteTemplate(draft)
                    dismiss()
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Esta plantilla se quitará de la lista. Las notificaciones ya programadas no se modifican.")
            }
        }
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Nombre de la plantilla")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            TextField("Ej. Pedido nuevo", text: $draft.name)
                .textFieldStyle(.plain)
                .padding(13)
                .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        }
    }

    private var imageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Miniatura de la notificación",
                subtitle: "Usa una imagen propia o un icono genérico. La cabecera del sistema siempre mostrará NotiLab."
            )

            HStack(spacing: 14) {
                TemplateIconView(template: draft, size: 66)
                    .overlay(alignment: .bottomTrailing) {
                        if isImportingImage {
                            ProgressView()
                                .tint(.white)
                                .padding(6)
                                .background(Color.black.opacity(0.55), in: Circle())
                        }
                    }

                VStack(alignment: .leading, spacing: 8) {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Label("Elegir imagen", systemImage: "photo.on.rectangle")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.nlAccent.opacity(0.12), in: Capsule())
                            .foregroundStyle(Color.nlAccent)
                    }
                    .buttonStyle(.plain)

                    if draft.imageName != nil {
                        Button(role: .destructive) {
                            draft.imageName = nil
                        } label: {
                            Label("Quitar imagen", systemImage: "trash")
                                .font(.caption.weight(.semibold))
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(Color.nlRed)
                    }
                }

                Spacer(minLength: 0)
            }

            Text("JPG o PNG, se recorta en cuadrado. La imagen se adjunta al aviso; el icono de NotiLab en la cabecera no cambia.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .nlCard()
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            isImportingImage = true
            Task { @MainActor in
                defer {
                    isImportingImage = false
                    selectedPhotoItem = nil
                }
                guard let data = try? await newItem.loadTransferable(type: Data.self),
                      let image = UIImage(data: data),
                      let filename = TemplateImageStore.shared.save(image: image) else {
                    return
                }
                draft.imageName = filename
            }
        }
    }

    private var presetPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(
                title: "Estilos rápidos",
                subtitle: "Iconos genéricos de tienda, música, mensajes, llamadas y más. No incluimos logotipos de marcas."
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(IconPreset.all) { preset in
                        Button {
                            draft.icon = preset.icon
                            draft.tint = preset.tint
                            draft.imageName = nil
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: preset.icon)
                                    .font(.system(size: 13, weight: .semibold))
                                Text(preset.name)
                                    .font(.caption.weight(.semibold))
                            }
                            .padding(.horizontal, 11)
                            .padding(.vertical, 8)
                            .background(
                                draft.icon == preset.icon && draft.tint == preset.tint && draft.imageName == nil
                                    ? preset.tint.color.opacity(0.20)
                                    : Color.primary.opacity(0.06),
                                in: Capsule()
                            )
                            .foregroundStyle(
                                draft.icon == preset.icon && draft.tint == preset.tint && draft.imageName == nil
                                    ? preset.tint.color
                                    : Color.secondary
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .nlCard()
    }

    private var iconPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Icono", subtitle: "Elige el símbolo que aparecerá en la vista previa y como miniatura.")

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6),
                spacing: 8
            ) {
                ForEach(TemplateIcon.all, id: \.self) { icon in
                    Button {
                        draft.imageName = nil
                        draft.icon = icon
                    } label: {
                        Image(systemName: icon)
                            .font(.system(size: 17, weight: .semibold))
                            .frame(width: 44, height: 44)
                            .foregroundStyle(draft.icon == icon ? .white : .secondary)
                            .background(
                                draft.icon == icon ? draft.tint.color : Color.primary.opacity(0.06),
                                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .nlCard()
    }

    private var tintPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Color", subtitle: "Se usa en la vista previa y en la app.")

            HStack(spacing: 12) {
                ForEach(TemplateTint.allCases) { tint in
                    Button {
                        draft.tint = tint
                    } label: {
                        Circle()
                            .fill(tint.color.gradient)
                            .frame(width: 30, height: 30)
                            .overlay {
                                Circle()
                                    .stroke(Color.primary.opacity(draft.tint == tint ? 0.75 : 0), lineWidth: 2)
                                    .padding(2)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .nlCard()
    }

    private var titleField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Título")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            TextField("Ej. Nuevo pedido", text: $draft.title)
                .textFieldStyle(.plain)
                .padding(13)
                .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        }
    }

    private var bodyEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mensaje")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            TextEditor(text: $draft.body)
                .scrollContentBackground(.hidden)
                .font(.body)
                .frame(minHeight: 104)
                .padding(8)
                .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                .overlay(alignment: .topLeading) {
                    if draft.body.isEmpty {
                        Text("Ej. {nombre} acaba de hacer un pedido.")
                            .font(.body)
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 13)
                            .padding(.vertical, 16)
                            .allowsHitTesting(false)
                    }
                }
        }
    }

    private var tokenRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Toca un token para añadirlo al mensaje")
                .font(.caption2)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                TokenChip(text: "{nombre}") {
                    appendToken("{nombre}")
                }
                TokenChip(text: "{ciudad}") {
                    appendToken("{ciudad}")
                }
                TokenChip(text: "{monto}") {
                    appendToken("{monto}")
                }
            }
        }
    }

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Vista previa")
            NotificationPreview(template: draft, payload: preview, timeLabel: "ahora")
        }
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            showDeleteAlert = true
        } label: {
            Label("Eliminar plantilla", systemImage: "trash")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.nlRed.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color.nlRed)
    }

    private func appendToken(_ token: String) {
        if draft.body.isEmpty {
            draft.body = token
        } else if draft.body.hasSuffix(" ") {
            draft.body += token
        } else {
            draft.body += " " + token
        }
    }

    private func save() {
        let trimmedName = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        nlHideKeyboard()
        draft.name = trimmedName
        draft.title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.body = draft.body.trimmingCharacters(in: .whitespacesAndNewlines)
        if originalImageName != draft.imageName {
            TemplateImageStore.shared.delete(named: originalImageName)
        }
        model.upsertTemplate(draft)
        dismiss()
    }
}

// MARK: - Token chip

struct TokenChip: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(.caption, design: .monospaced).weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color.nlAccent.opacity(0.12), in: Capsule())
                .foregroundStyle(Color.nlAccent)
        }
        .buttonStyle(.plain)
    }
}
