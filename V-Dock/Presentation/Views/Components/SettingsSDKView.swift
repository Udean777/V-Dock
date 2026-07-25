import SwiftUI

struct SettingsSDKView: View {
    @Environment(AppState.self) var state

    private var sdkPathBinding: Binding<String> {
        Binding(
            get: { state.androidSDKPath },
            set: { state.androidSDKPath = $0 }
        )
    }

    private var emulatorPath: String { "\(state.androidSDKPath)/emulator/emulator" }
    private var adbPath: String { "\(state.androidSDKPath)/platform-tools/adb" }
    private var emulatorExists: Bool { FileManager.default.fileExists(atPath: emulatorPath) }
    private var adbExists: Bool { FileManager.default.fileExists(atPath: adbPath) }

    var body: some View {
        Form {
            Section {
                HStack(spacing: 8) {
                    TextField("", text: sdkPathBinding)
                        .textFieldStyle(.roundedBorder)

                    Button("Browse") {
                        let panel = NSOpenPanel()
                        panel.canChooseFiles = false
                        panel.canChooseDirectories = true
                        panel.canCreateDirectories = false
                        panel.title = "Select Android SDK Directory"
                        panel.message = "Choose the Android SDK root folder"
                        if panel.runModal() == .OK {
                            state.androidSDKPath = panel.url?.path ?? ""
                        }
                    }
                }

                if state.androidSDKPath.isEmpty {
                    Text("Example: ~/Library/Android/sdk")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: state.hasAndroidSDK ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(state.hasAndroidSDK ? .green : .yellow)
                        Text(state.hasAndroidSDK ? "SDK found" : "Path not found")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Label("Android SDK Location", systemImage: "folder")
            }

            if state.hasAndroidSDK {
                Section {
                    ToolStatusRow(name: "Emulator", path: emulatorPath, exists: emulatorExists)
                    ToolStatusRow(name: "ADB", path: adbPath, exists: adbExists)
                } header: {
                    Label("Detected Tools", systemImage: "wrench")
                }
            }
        }
        .formStyle(.grouped)
    }
}

private struct ToolStatusRow: View {
    let name: String
    let path: String
    let exists: Bool

    var body: some View {
        HStack {
            Text(name)
                .fontWeight(.medium)
            Spacer()
            Image(systemName: exists ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(exists ? .green : .red)
                .help(path)
        }
        .font(.caption)
    }
}
