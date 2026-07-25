import SwiftUI

struct SettingsAboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            if let appIcon = NSImage(named: NSImage.applicationIconName) {
                Image(nsImage: appIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
            } else {
                Image(systemName: "display")
                    .font(.system(size: 48))
                    .foregroundStyle(.tint)
            }

            Text("V-Dock")
                .font(.title)
                .fontWeight(.medium)

            Text("Version \(appVersion) (Build \(buildNumber))")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()
                .frame(width: 200)

            Text("A macOS menu bar utility\nfor managing iOS Simulators\nand Android Emulators.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            Text("macOS \(macOSVersion)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    private var macOSVersion: String {
        let v = ProcessInfo.processInfo.operatingSystemVersion
        return "\(v.majorVersion).\(v.minorVersion).\(v.patchVersion)"
    }
}
