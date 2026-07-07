import SwiftUI

struct MenuBarLabel: View {
    @Environment(AppState.self) var state
    
    @State private var hasActive = false
    
    var body: some View {
        Group {
            if state.isProcessingAction {
                if let appIcon = getResizedAppIcon() {
                    Image(nsImage: appIcon)
                        .opacity(0.5) // Indicate processing
                } else {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .symbolEffect(.variableColor.iterative, options: .repeating, isActive: true)
                }
            } else {
                if let appIcon = getResizedAppIcon() {
                    Image(nsImage: appIcon)
                } else {
                    Image(systemName: hasActive ? "play.display" : "display")
                }
            }
        }
        .onAppear {
            hasActive = state.devices.contains { $0.status == .booted }
        }
        .onChange(of: state.devices.map { $0.status }) { _, _ in
            hasActive = state.devices.contains { $0.status == .booted }
        }
    }
    
    private func getResizedAppIcon() -> NSImage? {
        guard let appIcon = NSImage(named: NSImage.applicationIconName) else { return nil }
        
        let targetSize = NSSize(width: 18, height: 18)
        let resizedIcon = NSImage(size: targetSize)
        resizedIcon.lockFocus()
        appIcon.draw(in: NSRect(origin: .zero, size: targetSize), from: .zero, operation: .copy, fraction: 1.0)
        resizedIcon.unlockFocus()
        
        // This tells macOS to treat this image as a "template" so it automatically 
        // adapts to light/dark mode and blue selection highlights if it's monochrome.
        // It won't hurt color icons, but it's standard for Menu Bar items.
        // resizedIcon.isTemplate = true
        
        return resizedIcon
    }
}
