import SwiftUI

struct DeviceCardView: View {
    let device: Device
    let isPinned: Bool
    let resourceUsage: ResourceUsage?
    let onTogglePin: () -> Void
    let onPerformAction: (DeviceAction) async -> Void
    
    @Environment(AppState.self) var state
    
    @State private var showWipeConfirm = false
    @State private var showColdBootConfirm = false
    @State private var pushFileVM: PushFileViewModel?
    @State private var isTargetedForDrop = false
    
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
                    
                    if let vm = pushFileVM, vm.isTransferring {
                        ProgressView()
                            .controlSize(.small)
                            .padding(.leading, 4)
                    }
                    
                    Spacer()
                    StatusBadgeView(status: device.status)
                }
                if device.status == .booted, let usage = resourceUsage {
                    ResourceBarView(usage: usage)
                        .padding(.top, 2)
                }
            }
            
            if device.status == .booted {
                Button {
                    pushFileVM?.pickFileAndPush(to: device)
                } label: {
                    Image(systemName: "square.and.arrow.down")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Push File to Device")
                
                Button {
                    Task { await state.takeScreenshot(for: device) }
                } label: {
                    Image(systemName: "camera")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Take Screenshot")
                
                let isRecording = state.recordingDeviceID == device.id
                Button {
                    Task { await state.toggleRecording(for: device) }
                } label: {
                    Image(systemName: isRecording ? "stop.circle.fill" : "record.circle")
                        .foregroundStyle(isRecording ? .red : .secondary)
                        .symbolEffect(.pulse, options: .repeating, isActive: isRecording)
                }
                .buttonStyle(.plain)
                .help(isRecording ? "Stop Recording" : "Start Recording")
            }
            
            pinButton
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(isTargetedForDrop ? Color.accentColor.opacity(0.1) : Color.clear)
        .cornerRadius(8)
        .dropDestination(for: URL.self) { urls, _ in
            guard !urls.isEmpty, device.status == .booted else { return false }
            Task { @MainActor in
                await pushFileVM?.push(files: urls, to: device)
            }
            return true
        } isTargeted: { targeted in
            if device.status == .booted {
                isTargetedForDrop = targeted
            }
        }
        .contextMenu {
            if device.platform == .ios {
                if device.status == .shutdown {
                    Button("Boot", systemImage: "play") { Task { await state.perform(.boot, on: device) } }
                } else {
                    Button("Shutdown", systemImage: "stop") { Task { await state.perform(.shutdown, on: device) } }
                    Button("Force Kill", systemImage: "xmark.octagon") { Task { await state.perform(.forceKill, on: device) } }
                    Divider()
                    Menu("Appearance", systemImage: "paintbrush") {
                        Button("Dark Mode", systemImage: "moon.fill") { Task { await state.setDarkMode(for: device, isDark: true) } }
                        Button("Light Mode", systemImage: "sun.max.fill") { Task { await state.setDarkMode(for: device, isDark: false) } }
                    }
                    Button("Show Logcat", systemImage: "list.bullet.rectangle") { state.openLogcat(for: device) }
                    Divider()
                    Button("Cold Boot", systemImage: "bolt") { showColdBootConfirm = true }
                }
                Button("Erase All Content & Settings", systemImage: "trash", role: .destructive) { showWipeConfirm = true }
            }
            
            if device.platform == .android {
                if device.status == .shutdown {
                    Button("Boot", systemImage: "play") { Task { await state.perform(.boot, on: device) } }
                    Button("Cold Boot", systemImage: "bolt") { showColdBootConfirm = true }
                } else {
                    Button("Shutdown", systemImage: "stop") { Task { await state.perform(.shutdown, on: device) } }
                    Button("Force Kill", systemImage: "xmark.octagon") { Task { await state.perform(.forceKill, on: device) } }
                    Divider()
                    Menu("Appearance", systemImage: "paintbrush") {
                        Button("Dark Mode", systemImage: "moon.fill") { Task { await state.setDarkMode(for: device, isDark: true) } }
                        Button("Light Mode", systemImage: "sun.max.fill") { Task { await state.setDarkMode(for: device, isDark: false) } }
                    }
                    Button("Show Logcat", systemImage: "list.bullet.rectangle") { state.openLogcat(for: device) }
                    Divider()
                    Button("Cold Boot (Restart)", systemImage: "bolt.fill") { showColdBootConfirm = true }
                }
                Button("Wipe Data", systemImage: "trash", role: .destructive) { showWipeConfirm = true }
            }
        }
        .alert("Erase \(device.name)?", isPresented: $showWipeConfirm) {
            Button(device.platform == .ios ? "Erase All Content" : "Wipe Data", role: .destructive) {
                Task { await onPerformAction(.wipeData) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(device.platform == .ios
                ? "This will permanently erase all content and settings on this simulator, including installed apps and their data."
                : "This will wipe all user data on this emulator. The AVD configuration will remain intact.")
        }
        .alert("Cold Boot \(device.name)?", isPresented: $showColdBootConfirm) {
            Button("Cold Boot", role: .destructive) {
                Task { await onPerformAction(.coldBoot) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The device will be shut down and restarted from a clean state, discarding any saved snapshot.")
        }
        .onAppear {
            if pushFileVM == nil {
                pushFileVM = PushFileViewModel(useCase: state.pushFileUseCase)
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
