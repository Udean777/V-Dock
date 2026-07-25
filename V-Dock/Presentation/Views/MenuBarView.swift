import SwiftUI

struct MenuBarView: View {
    @Environment(AppState.self) var state
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 8) {
                if let appIcon = NSImage(named: NSImage.applicationIconName) {
                    Image(nsImage: appIcon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                }
                
                Text("V-Dock")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                    Text("v\(version)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)
                }
                
                Spacer()
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            
            Divider()
            
            ScrollView {
                VStack(spacing: 16) {
                    let running = state.devices.filter { $0.status == .booted }
                    
                    // Running Devices Section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Running Devices")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                            Spacer()
                            if !running.isEmpty {
                                Button {
                                    Task {
                                        for device in running {
                                            await state.perform(.shutdown, on: device)
                                        }
                                    }
                                } label: {
                                    Text("Stop All")
                                        .font(.caption)
                                        .bold()
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.plain)
                                .disabled(state.isProcessingAction)
                            }
                        }
                        
                        if running.isEmpty {
                            VStack(spacing: 6) {
                                Image(systemName: "sleep")
                                    .font(.largeTitle)
                                    .foregroundStyle(.tertiary)
                                Text("No running devices")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(NSColor.controlBackgroundColor).opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
                        } else {
                            ForEach(running) { device in
                                MenuBarDeviceRow(device: device, state: state)
                            }
                        }
                    }
                    
                    // Pinned Devices Section
                    let offlinePinned = state.pinnedDevices.filter { $0.status != .booted }
                    if !offlinePinned.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Pinned Devices")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                            
                            ForEach(offlinePinned) { device in
                                MenuBarDeviceRow(device: device, state: state)
                            }
                        }
                    }
                }
                .padding()
            }
            .frame(height: 350)
            
            Divider()
            
            // Footer
            VStack(spacing: 8) {
                Button {
                    openDashboardWindow()
                } label: {
                    HStack {
                        Image(systemName: "macwindow.on.rectangle")
                        Text("Open Dashboard")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                
                Button("Pair Wireless Device", systemImage: "wifi") {
                    openPairingWindow()
                }
                .buttonStyle(.link)
                
                Divider()
                
                HStack {
                    Button("Settings") {
                        openSettingsWindow()
                    }
                    .buttonStyle(.link)
                    .keyboardShortcut(",", modifiers: .command)
                    
                    Spacer()
                    
                    Button("Quit") {
                        UserDefaults.standard.set(true, forKey: "shouldTerminate")
                        NSApplication.shared.terminate(nil)
                    }
                    .buttonStyle(.link)
                    .foregroundStyle(.red)
                }
                .padding(.top, 4)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        }
        .frame(width: 300)
        .background(.regularMaterial)
        .task {
            while !Task.isCancelled {
                await state.refresh()
                try? await Task.sleep(nanoseconds: 10_000_000_000)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("OpenSettings"))) { _ in
            openSettingsWindow()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("OpenLogcat"))) { notification in
            if let device = notification.object as? Device {
                openLogcatWindow(for: device)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("OpenPairing"))) { _ in
            openPairingWindow()
        }
    }
    
    private func openDashboardWindow() {
        NSApp.setActivationPolicy(.regular)
        
        if let window = NSApp.windows.first(where: { $0.title == "Dashboard" || $0.title == "Devices" }) {
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered, defer: false)
        window.center()
        window.title = "Dashboard"
        window.isRestorable = false
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: DashboardView().environment(state))
        setupWindowObserver(for: window)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func openSettingsWindow() {
        NSApp.setActivationPolicy(.regular)
        
        if let window = NSApp.windows.first(where: { $0.title == "Settings" }) {
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 350),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered, defer: false)
        window.center()
        window.title = "Settings"
        window.isRestorable = false
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: SettingsView().environment(state))
        setupWindowObserver(for: window)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func openLogcatWindow(for device: Device) {
        NSApp.setActivationPolicy(.regular)
        
        let windowTitle = "Logcat: \(device.name)"
        if let window = NSApp.windows.first(where: { $0.title == windowTitle }) {
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered, defer: false)
        window.center()
        window.title = windowTitle
        window.isRestorable = false
        window.isReleasedWhenClosed = false
        
        window.contentView = NSHostingView(rootView: LogcatView(device: device).environment(state))
        
        setupWindowObserver(for: window)
        
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func openPairingWindow() {
        NSApp.setActivationPolicy(.regular)

        if let window = NSApp.windows.first(where: { $0.title == "Pair Wireless Device" }) {
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 500),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered, defer: false)
        window.center()
        window.title = "Pair Wireless Device"
        window.isRestorable = false
        window.isReleasedWhenClosed = true
        window.contentView = NSHostingView(
            rootView: PairDeviceView(pairingUseCase: state.pairingUseCase)
        )

        setupWindowObserver(for: window)

        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
        window.setContentSize(NSSize(width: 420, height: 500))
    }

    private func setupWindowObserver(for window: NSWindow) {
        NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: window, queue: .main) { _ in
            let remainingWindows = NSApp.windows.filter {
                $0 != window && $0.isVisible && ($0.title == "Dashboard" || $0.title == "Devices" || $0.title == "Settings" || $0.title.hasPrefix("Logcat: ") || $0.title == "Pair Wireless Device")
            }
            if remainingWindows.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    NSApp.setActivationPolicy(.accessory)
                }
            }
        }
    }
}

struct MenuBarDeviceRow: View {
    let device: Device
    let state: AppState
    
    @State private var pushFileVM: PushFileViewModel?
    @State private var isTargetedForDrop = false
    
    var body: some View {
        HStack {
            Image(systemName: device.platform == .ios ? "apple.logo" : "a.circle.fill")
                .font(.title2)
                .foregroundStyle(device.platform == .ios ? .gray : .green)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(device.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                HStack {
                    StatusBadgeView(status: device.status)
                    if let vm = pushFileVM, vm.isTransferring {
                        ProgressView()
                            .controlSize(.small)
                            .scaleEffect(0.7)
                    }
                }
            }
            
            Spacer()
            
            if device.status == .booted {
                Button {
                    pushFileVM?.pickFileAndPush(to: device)
                } label: {
                    Image(systemName: "square.and.arrow.down")
                        .font(.caption)
                        .padding(6)
                        .background(Color.secondary.opacity(0.1), in: Circle())
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Push File to Device")
                
                Button {
                    Task { await state.takeScreenshot(for: device) }
                } label: {
                    Image(systemName: "camera")
                        .font(.caption)
                        .padding(6)
                        .background(Color.secondary.opacity(0.1), in: Circle())
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Take Screenshot")
                
                let isRecording = state.recordingDeviceID == device.id
                Button {
                    Task { await state.toggleRecording(for: device) }
                } label: {
                    Image(systemName: isRecording ? "stop.fill" : "record.circle")
                        .font(.caption)
                        .padding(6)
                        .background(isRecording ? Color.red.opacity(0.2) : Color.secondary.opacity(0.1), in: Circle())
                        .foregroundStyle(isRecording ? .red : .secondary)
                        .symbolEffect(.pulse, options: .repeating, isActive: isRecording)
                }
                .buttonStyle(.plain)
                .help(isRecording ? "Stop Recording" : "Start Recording")
            }
            
            Button {
                let action: DeviceAction = device.status == .booted ? .shutdown : .boot
                Task { await state.perform(action, on: device) }
            } label: {
                Image(systemName: device.status == .booted ? "power" : "play.fill")
                    .font(.caption)
                    .padding(6)
                    .background(device.status == .booted ? Color.red.opacity(0.1) : Color.green.opacity(0.1), in: Circle())
                    .foregroundStyle(device.status == .booted ? .red : .green)
            }
            .buttonStyle(.plain)
            .disabled(state.isProcessingAction)
        }
        .padding(12)
        .background(isTargetedForDrop ? Color.accentColor.opacity(0.2) : Color(NSColor.controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
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
                    Button("Cold Boot", systemImage: "bolt") { confirmColdBoot() }
                }
                Button("Erase All Content & Settings", systemImage: "trash", role: .destructive) { confirmWipe() }
            }
            
            if device.platform == .android {
                if device.status == .shutdown {
                    Button("Boot", systemImage: "play") { Task { await state.perform(.boot, on: device) } }
                    Button("Cold Boot", systemImage: "bolt") { confirmColdBoot() }
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
                    Button("Cold Boot (Restart)", systemImage: "bolt.fill") { confirmColdBoot() }
                }
                Button("Wipe Data", systemImage: "trash", role: .destructive) { confirmWipe() }
            }
        }
        .onAppear {
            if pushFileVM == nil {
                pushFileVM = PushFileViewModel(useCase: state.pushFileUseCase)
            }
        }
    }
    
    private func confirmWipe() {
        let alert = NSAlert()
        alert.messageText = "Erase \(device.name)?"
        alert.informativeText = device.platform == .ios
            ? "This will permanently erase all content and settings on this simulator, including installed apps and their data."
            : "This will wipe all user data on this emulator. The AVD configuration will remain intact."
        alert.alertStyle = .warning
        alert.addButton(withTitle: device.platform == .ios ? "Erase All Content" : "Wipe Data")
        alert.addButton(withTitle: "Cancel")
        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            Task {
                await state.perform(.wipeData, on: device)
            }
        }
    }
    
    private func confirmColdBoot() {
        let alert = NSAlert()
        alert.messageText = "Cold Boot \(device.name)?"
        alert.informativeText = "The device will be shut down and restarted from a clean state, discarding any saved snapshot."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Cold Boot")
        alert.addButton(withTitle: "Cancel")
        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            Task {
                await state.perform(.coldBoot, on: device)
            }
        }
    }
}
