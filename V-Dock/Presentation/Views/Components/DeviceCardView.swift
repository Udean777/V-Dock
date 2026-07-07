import SwiftUI

struct DeviceCardView: View {
    let device: Device
    let isPinned: Bool
    let resourceUsage: ResourceUsage?
    let onTogglePin: () -> Void
    let onPerformAction: (DeviceAction) async -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            platformIcon
                .font(.title2)
                .foregroundStyle(accentColor)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(device.name)
                        .font(.body)
                    Spacer()
                    StatusBadgeView(status: device.status)
                }
                if device.status == .booted, let usage = resourceUsage {
                    ResourceBarView(usage: usage)
                        .padding(.top, 2)
                }
            }
            
            pinButton
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .contextMenu {
            if device.status == .shutdown {
                Button("Boot", systemImage: "play") {
                    Task { await onPerformAction(.boot) }
                }
            } else {
                Button("Shutdown", systemImage: "stop") {
                    Task { await onPerformAction(.shutdown) }
                }
                Button("Force Kill", systemImage: "xmark.octagon") {
                    Task { await onPerformAction(.forceKill) }
                }
            }
            if device.platform == .android {
                Divider()
                Button("Cold Boot", systemImage: "bolt") {
                    Task { await onPerformAction(.coldBoot) }
                }
                Button("Wipe Data", systemImage: "trash") {
                    Task { await onPerformAction(.wipeData) }
                }
            }
        }
    }
    
    private var platformIcon: some View {
        switch device.platform {
        case .ios:
            Image(systemName: "iphone")
        case .android:
            Image(systemName: "smartphone")
        }
    }
    
    private var accentColor: Color {
        switch device.platform {
        case .ios: .blue
        case .android: .green
        }
    }
    
    private var pinButton: some View {
        Button {
            onTogglePin()
        } label: {
            Image(systemName: isPinned ? "star.fill" : "star")
                .foregroundStyle(isPinned ? .yellow : .secondary.opacity(0.4))
        }
        .buttonStyle(.plain)
        .help(isPinned ? "Unpin" : "Pin to menu bar")
    }
}
