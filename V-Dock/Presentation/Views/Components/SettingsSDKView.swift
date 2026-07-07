import SwiftUI

struct SettingsSDKView: View {
    @Environment(AppState.self) var state
    
    var body: some View {
        Form {
            Section {
                HStack(spacing: 8) {
                    TextField("", text: Binding(
                        get: { state.androidSDKPath },
                        set: { state.androidSDKPath = $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .font(.body)
                    
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
                
                if !state.androidSDKPath.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: state.hasAndroidSDK ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(state.hasAndroidSDK ? .green : .yellow)
                        Text(state.hasAndroidSDK ? "SDK found" : "Path not found")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("Example: ~/Library/Android/sdk")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            } header: {
                Label("Android SDK Location", systemImage: "folder")
            }
            
            if state.hasAndroidSDK {
                Section {
                    let emulatorPath = "\(state.androidSDKPath)/emulator/emulator"
                    let adbPath = "\(state.androidSDKPath)/platform-tools/adb"
                    let emulatorExists = FileManager.default.fileExists(atPath: emulatorPath)
                    let adbExists = FileManager.default.fileExists(atPath: adbPath)
                    
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
