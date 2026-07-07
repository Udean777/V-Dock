import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) var state
    @State private var selectedTab: SettingsTab = .sdk

    enum SettingsTab: String, CaseIterable {
        case sdk
        case general
        case about

        var label: String {
            switch self {
            case .sdk: "Android SDK"
            case .general: "General"
            case .about: "About"
            }
        }

        var icon: String {
            switch self {
            case .sdk: "gearshape"
            case .general: "switch.2"
            case .about: "info.circle"
            }
        }
    }

    var body: some View {
        TabView {
            SettingsGeneralView()
                .tabItem {
                    Label("General", systemImage: "switch.2")
                }
                
            SettingsSDKView()
                .tabItem {
                    Label("Android SDK", systemImage: "gearshape")
                }
                
            SettingsAboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 500, height: 350)
    }
}
