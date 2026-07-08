import SwiftUI

struct DestructiveActionAlert: ViewModifier {
    let title: String
    let message: String
    let confirmLabel: String
    @Binding var isPresented: Bool
    let onConfirm: () async -> Void
    
    func body(content: Content) -> some View {
        content
            .onChange(of: isPresented) { _, newValue in
                if newValue {
                    showAlert()
                }
            }
    }
    
    private func showAlert() {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        
        alert.addButton(withTitle: confirmLabel)
        alert.addButton(withTitle: "Cancel")
        
        // Activate app so alert comes to front without closing the menu bar if possible
        NSApp.activate(ignoringOtherApps: true)
        
        let response = alert.runModal()
        
        // Must dispatch the state update and action to avoid UI thread conflicts
        DispatchQueue.main.async {
            self.isPresented = false
            if response == .alertFirstButtonReturn {
                Task { await onConfirm() }
            }
        }
    }
}

extension View {
    func destructiveActionAlert(
        title: String,
        message: String,
        confirmLabel: String,
        isPresented: Binding<Bool>,
        onConfirm: @escaping () async -> Void
    ) -> some View {
        modifier(DestructiveActionAlert(
            title: title,
            message: message,
            confirmLabel: confirmLabel,
            isPresented: isPresented,
            onConfirm: onConfirm
        ))
    }
}
