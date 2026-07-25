import SwiftUI

struct SettingsView: View {
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
