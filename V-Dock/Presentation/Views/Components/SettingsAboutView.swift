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
            
            VStack(spacing: 4) {
                Text("A macOS menu bar utility")
                    .font(.caption)
                Text("for managing iOS Simulators")
                    .font(.caption)
                Text("and Android Emulators.")
                    .font(.caption)
            }
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
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }
    
    private var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }
    
    private var macOSVersion: String {
        let process = ProcessInfo.processInfo
        let version = process.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }
}
