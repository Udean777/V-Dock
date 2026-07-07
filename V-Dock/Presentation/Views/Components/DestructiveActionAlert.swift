import SwiftUI

struct DestructiveActionAlert: ViewModifier {
    let title: String
    let message: String
    let confirmLabel: String
    @Binding var isPresented: Bool
    let onConfirm: () async -> Void
    
    func body(content: Content) -> some View {
        content
            .alert(title, isPresented: $isPresented) {
                Button(confirmLabel, role: .destructive) {
                    Task { await onConfirm() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(message)
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
