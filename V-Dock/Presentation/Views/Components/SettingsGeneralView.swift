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
            
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "display")
                            .font(.title2)
                            .foregroundStyle(.tint)
                        VStack(alignment: .leading) {
                            Text("V-Dock")
                                .font(.headline)
                            Text("Version \(appVersion)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Label("About", systemImage: "info.circle")
            }
        }
        .formStyle(.grouped)
    }
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}
