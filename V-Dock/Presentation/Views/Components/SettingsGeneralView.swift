import SwiftUI

struct SettingsGeneralView: View {
    @Environment(AppState.self) var state

    var body: some View {
        Form {
            Section {
                Toggle(isOn: Binding(
                    get: { state.isLaunchAtLoginEnabled },
                    set: { state.isLaunchAtLoginEnabled = $0 }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Launch at Login")
                        Text("Automatically start V-Dock when you log in")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Label("Startup", systemImage: "power")
            }
        }
        .formStyle(.grouped)
    }
}
