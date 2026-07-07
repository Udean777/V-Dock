import SwiftUI

struct StatusBadgeView: View {
    let status: DeviceStatus
    
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .opacity(status == .booted ? (isAnimating ? 1 : 0.4) : 0.5)
                .animation(status == .booted ? .easeInOut(duration: 1).repeatForever(autoreverses: true) : .default, value: isAnimating)
            Text(label)
                .font(.caption)
                .foregroundStyle(color)
        }
        .onAppear {
            isAnimating = (status == .booted)
        }
        .onChange(of: status) { _, newValue in
            if newValue == .booted {
                isAnimating = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    isAnimating = true
                }
            } else {
                isAnimating = false
            }
        }
    }
    
    var color: Color {
        switch status {
        case .booted: .green
        case .booting: .orange
        case .shutdown: .secondary
        }
    }
    
    var label: String {
        switch status {
        case .booted: "Booted"
        case .booting: "Booting"
        case .shutdown: "Shutdown"
        }
    }
}
