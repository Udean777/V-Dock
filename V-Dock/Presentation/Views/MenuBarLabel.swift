import SwiftUI

struct MenuBarLabel: View {
    @Environment(AppState.self) var state
    
    @State private var hasActive = false
    
    var body: some View {
        Group {
            if state.isProcessingAction {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .symbolEffect(.variableColor.iterative, options: .repeating, isActive: true)
            } else {
                Image(systemName: hasActive ? "play.display" : "display")
            }
        }
        .onAppear {
            hasActive = state.devices.contains { $0.status == .booted }
        }
        .onChange(of: state.devices.map { $0.status }) { _, _ in
            hasActive = state.devices.contains { $0.status == .booted }
        }
    }
}
