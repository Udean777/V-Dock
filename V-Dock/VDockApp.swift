import SwiftUI

@main
struct VDockApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    let container = DependencyContainer()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environment(container.appState)
        } label: {
            MenuBarLabel()
                .environment(container.appState)
        }
        .menuBarExtraStyle(.window)
    }
}
