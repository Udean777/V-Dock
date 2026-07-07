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
                    if !state.pinnedDevices.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Pinned Devices")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                            
                            ForEach(state.pinnedDevices) { device in
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
    }
    
    private func openDashboardWindow() {
        NSApp.setActivationPolicy(.regular)
        
        if let window = NSApp.windows.first(where: { $0.title == "Dashboard" || $0.title == "Devices" }) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    private func openSettingsWindow() {
        NSApp.setActivationPolicy(.regular)
        
        if let window = NSApp.windows.first(where: { $0.title == "Settings" }) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    private func setupWindowObserver(for window: NSWindow) {
        NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: window, queue: .main) { _ in
            let remainingWindows = NSApp.windows.filter { 
                $0 != window && $0.isVisible && ($0.title == "Dashboard" || $0.title == "Devices" || $0.title == "Settings") 
            }
            if remainingWindows.isEmpty {
                NSApp.setActivationPolicy(.accessory)
            }
        }
    }
}

struct MenuBarDeviceRow: View {
    let device: Device
    let state: AppState
    
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
                
                StatusBadgeView(status: device.status)
            }
            
            Spacer()
            
            Button {
                let action: DeviceAction = device.status == .booted ? .shutdown : .boot
                Task { await state.perform(action, on: device) }
            } label: {
                Image(systemName: device.status == .booted ? "stop.fill" : "play.fill")
                    .font(.caption)
                    .padding(8)
                    .background(device.status == .booted ? Color.red.opacity(0.1) : Color.green.opacity(0.1), in: Circle())
                    .foregroundStyle(device.status == .booted ? .red : .green)
            }
            .buttonStyle(.plain)
            .disabled(state.isProcessingAction)
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
    }
}
