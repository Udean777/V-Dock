import SwiftUI

struct StatusBadgeView: View {
    let status: DeviceStatus
    
    var body: some View {
        HStack(spacing: 4) {
            if status == .booted {
                Image(systemName: "circle.fill")
                    .resizable()
                    .frame(width: 8, height: 8)
                    .foregroundStyle(color)
                    .symbolEffect(.pulse, options: .repeating)
            } else {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                    .opacity(0.5)
            }
            Text(label)
                .font(.caption)
                .foregroundStyle(color)
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
