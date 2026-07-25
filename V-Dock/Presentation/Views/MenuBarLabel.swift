import SwiftUI

struct MenuBarLabel: View {
    @Environment(AppState.self) var state

    var body: some View {
        Group {
            if state.isProcessingAction {
                if let icon = appIcon {
                    Image(nsImage: icon)
                        .opacity(0.5)
                } else {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .symbolEffect(.variableColor.iterative, options: .repeating, isActive: true)
                }
            } else {
                if let icon = appIcon {
                    Image(nsImage: icon)
                } else {
                    Image(systemName: state.devices.contains { $0.status == .booted } ? "play.display" : "display")
                }
            }
        }
    }

    private var appIcon: NSImage? {
        guard let icon = NSImage(named: NSImage.applicationIconName) else { return nil }
        let targetSize = NSSize(width: 18, height: 18)
        let resized = NSImage(size: targetSize)
        resized.lockFocus()
        icon.draw(in: NSRect(origin: .zero, size: targetSize), from: .zero, operation: .copy, fraction: 1.0)
        resized.unlockFocus()
        return resized
    }
}
