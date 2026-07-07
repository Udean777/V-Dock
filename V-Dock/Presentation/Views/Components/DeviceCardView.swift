import SwiftUI

struct DeviceCardView: View {
    let device: Device
    let isPinned: Bool
    let resourceUsage: ResourceUsage?
    let onTogglePin: () -> Void
    let onPerformAction: (DeviceAction) async -> Void
    
    @State private var showWipeConfirm = false
    @State private var showColdBootConfirm = false
    
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
            if device.platform == .ios {
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
                    Divider()
                    Button("Cold Boot", systemImage: "bolt") {
                        showColdBootConfirm = true
                    }
                }
                Button("Erase All Content & Settings", systemImage: "trash", role: .destructive) {
                    showWipeConfirm = true
                }
            }
            
            if device.platform == .android {
                if device.status == .shutdown {
                    Button("Boot", systemImage: "play") {
                        Task { await onPerformAction(.boot) }
                    }
                    Button("Cold Boot", systemImage: "bolt") {
                        showColdBootConfirm = true
                    }
                } else {
                    Button("Shutdown", systemImage: "stop") {
                        Task { await onPerformAction(.shutdown) }
                    }
                    Button("Force Kill", systemImage: "xmark.octagon") {
                        Task { await onPerformAction(.forceKill) }
                    }
                    Divider()
                    Button("Cold Boot (Restart)", systemImage: "bolt.fill") {
                        showColdBootConfirm = true
                    }
                }
                Button("Wipe Data", systemImage: "trash", role: .destructive) {
                    showWipeConfirm = true
                }
            }
        }
        .destructiveActionAlert(
            title: "Erase \(device.name)?",
            message: device.platform == .ios
                ? "This will permanently erase all content and settings on this simulator, including installed apps and their data."
                : "This will wipe all user data on this emulator. The AVD configuration will remain intact.",
            confirmLabel: device.platform == .ios ? "Erase All Content" : "Wipe Data",
            isPresented: $showWipeConfirm
        ) {
            await onPerformAction(.wipeData)
        }
        .destructiveActionAlert(
            title: "Cold Boot \(device.name)?",
            message: "The device will be shut down and restarted from a clean state, discarding any saved snapshot.",
            confirmLabel: "Cold Boot",
            isPresented: $showColdBootConfirm
        ) {
            await onPerformAction(.coldBoot)
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
