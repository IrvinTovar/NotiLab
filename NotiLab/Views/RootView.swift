import SwiftUI

enum AppTab: Hashable {
    case schedule
    case templates
    case settings
}

struct RootView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.scenePhase) private var scenePhase

    @State private var tab: AppTab

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-templates") {
            _tab = State(initialValue: .templates)
        } else if arguments.contains("-settings") {
            _tab = State(initialValue: .settings)
        } else {
            _tab = State(initialValue: .schedule)
        }
    }

    var body: some View {
        TabView(selection: $tab) {
            ScheduleView()
                .tabItem {
                    Label("Programar", systemImage: "bell.badge.fill")
                }
                .tag(AppTab.schedule)

            TemplatesView(selectedTab: $tab)
                .tabItem {
                    Label("Plantillas", systemImage: "square.stack.3d.up.fill")
                }
                .tag(AppTab.templates)

            SettingsView()
                .tabItem {
                    Label("Ajustes", systemImage: "gearshape.fill")
                }
                .tag(AppTab.settings)
        }
        .tint(.nlAccent)
        .overlay(alignment: .bottom) {
            if let toast = model.toast {
                ToastView(text: toast)
                    .padding(.bottom, 88)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.86), value: model.toast)
        .task {
            await model.refresh()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            Task { await model.refresh() }
        }
        .alert(
            "No se pudo programar",
            isPresented: Binding(
                get: { model.errorMessage != nil },
                set: { if !$0 { model.errorMessage = nil } }
            )
        ) {
            Button("Entendido", role: .cancel) {}
        } message: {
            Text(model.errorMessage ?? "")
        }
    }
}
