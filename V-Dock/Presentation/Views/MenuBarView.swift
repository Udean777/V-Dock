import SwiftUI

struct MenuBarView: View {
    @Environment(AppState.self) var state

    var body: some View {
        VStack(spacing: 0) {
            header
            deviceList
            footer
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

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            if let appIcon = NSImage(named: NSImage.applicationIconName) {
                Image(nsImage: appIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 18, height: 18)
            }

            Text("V-Dock")
                .font(.headline)
                .fontWeight(.semibold)

            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                Text("v\(version)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            if state.isRefreshing {
                ProgressView()
                    .controlSize(.small)
                    .scaleEffect(0.7)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - Device List

    private var deviceList: some View {
        let running = state.devices.filter { $0.status == .booted }
        let offlinePinned = state.pinnedDevices.filter { $0.status != .booted }

        return ScrollView {
            VStack(spacing: 0) {
                if !running.isEmpty {
                    SectionHeader(title: "Running Devices", count: running.count) {
                        Button("Stop All") {
                            Task {
                                for device in running {
                                    await state.perform(.shutdown, on: device)
                                }
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.red)
                        .buttonStyle(.plain)
                        .disabled(state.isProcessingAction)
                    }
                    sectionContent {
                        ForEach(running) { device in
                            MenuBarDeviceRow(device: device, state: state)
                        }
                    }
                }

                if running.isEmpty && offlinePinned.isEmpty {
                    emptyState
                }

                if !offlinePinned.isEmpty {
                    SectionHeader(title: "Pinned Devices", count: offlinePinned.count) { EmptyView() }
                    sectionContent {
                        ForEach(offlinePinned) { device in
                            MenuBarDeviceRow(device: device, state: state)
                        }
                    }
                }
            }
            .padding(.vertical, 6)
        }
        .frame(height: 320)
    }

    private func sectionContent(@ViewBuilder _ content: () -> some View) -> some View {
        VStack(spacing: 2) {
            content()
        }
        .padding(.horizontal, 8)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer().frame(height: 12)
            Image(systemName: "rectangle.3.group")
                .font(.title3)
                .foregroundStyle(.tertiary)
            Text("No devices detected")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("Refresh automatically every 10s")
                .font(.caption2)
                .foregroundStyle(.tertiary)
            Spacer().frame(height: 12)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 0) {
            Divider()

            updateStatusRow
                .padding(.horizontal, 14)
                .padding(.vertical, 6)

            VStack(spacing: 6) {
                Button {
                    openDashboardWindow()
                } label: {
                    Label("Open Dashboard", systemImage: "macwindow.on.rectangle")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 7))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)

                HStack(spacing: 8) {
                    Button("Pair Wireless", systemImage: "wifi") {
                        openPairingWindow()
                    }
                    .buttonStyle(.link)
                    .font(.caption)

                    Spacer()

                    Button("Settings", systemImage: "gearshape") {
                        openSettingsWindow()
                    }
                    .buttonStyle(.link)
                    .font(.caption)
                    .keyboardShortcut(",", modifiers: .command)

                    Button("Quit", systemImage: "xmark") {
                        UserDefaults.standard.set(true, forKey: "shouldTerminate")
                        NSApplication.shared.terminate(nil)
                    }
                    .buttonStyle(.link)
                    .font(.caption)
                    .foregroundStyle(.red)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
    }

    @ViewBuilder
    private var updateStatusRow: some View {
        let vm = state.updateChecker
        switch vm.state {
        case .idle:
            Button("Check for Updates…") {
                Task { await vm.check() }
            }
            .buttonStyle(.link)
            .font(.caption)

        case .checking:
            HStack(spacing: 6) {
                ProgressView()
                    .controlSize(.small)
                    .scaleEffect(0.7)
                Text("Checking for Updates…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

        case .upToDate(let v):
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.green)
                Text("Up to date (v\(v))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

        case .updateAvailable(let version):
            Button {
                Task { await vm.downloadAndInstall() }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                    Text("Update v\(version) → Download")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }
            .buttonStyle(.plain)

        case .downloading(let progress, let version):
            HStack(spacing: 6) {
                ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(.linear)
                    .frame(width: 60)
                Text("Downloading v\(version)…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

        case .downloaded(_, let version):
            Button {
                vm.install()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.green)
                    Text("v\(version) ready — Install Now")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
            .buttonStyle(.plain)

        case .error(let msg):
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption2)
                    .foregroundStyle(.orange)
                Text(msg)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .help(msg)
        }
    }

    // MARK: - Window management

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

// MARK: - Device Row

struct MenuBarDeviceRow: View {
    let device: Device
    let state: AppState

    @State private var pushFileVM: PushFileViewModel?
    @State private var isTargetedForDrop = false

    var body: some View {
        HStack(spacing: 0) {
            statusDot
                .padding(.trailing, 8)

            VStack(alignment: .leading, spacing: 1) {
                Text(device.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    StatusBadgeView(status: device.status)
                    if device.status == .booted {
                        Text(device.platform == .ios ? "Simulator" : "Emulator")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    if let vm = pushFileVM, vm.isTransferring {
                        ProgressView()
                            .controlSize(.small)
                            .scaleEffect(0.6)
                    }
                }
            }

            Spacer(minLength: 4)

            if device.status == .booted {
                HStack(spacing: 2) {
                    Menu {
                        Button {
                            pushFileVM?.pickFileAndPush(to: device)
                        } label: {
                            Label("Push File...", systemImage: "square.and.arrow.down")
                        }

                        Button {
                            Task { await state.takeScreenshot(for: device) }
                        } label: {
                            Label("Take Screenshot", systemImage: "camera")
                        }

                        let isRecording = state.recordingDeviceID == device.id
                        Button {
                            Task { await state.toggleRecording(for: device) }
                        } label: {
                            Label(isRecording ? "Stop Recording" : "Start Recording", systemImage: isRecording ? "stop.fill" : "record.circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(6)
                    }
                    .menuStyle(.borderlessButton)
                    .menuIndicator(.hidden)
                    .fixedSize()
                    .help("More actions")

                    powerButton
                }
            } else {
                powerButton
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(isTargetedForDrop ? Color.accentColor.opacity(0.15) : Color.clear, in: RoundedRectangle(cornerRadius: 8))
        .background(.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 8))
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
            if device.status == .shutdown {
                Button("Boot", systemImage: "play") { Task { await state.perform(.boot, on: device) } }
                if device.platform == .android {
                    Button("Cold Boot", systemImage: "bolt") { confirmColdBoot() }
                }
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
            Button(device.platform == .ios ? "Erase All Content & Settings" : "Wipe Data",
                   systemImage: "trash", role: .destructive) { confirmWipe() }
        }
        .onAppear {
            if pushFileVM == nil {
                pushFileVM = PushFileViewModel(useCase: state.pushFileUseCase)
            }
        }
    }

    private var statusDot: some View {
        Circle()
            .fill(device.status == .booted ? Color.green : Color.secondary.opacity(0.4))
            .frame(width: 6, height: 6)
    }

    private var powerButton: some View {
        Button {
            let action: DeviceAction = device.status == .booted ? .shutdown : .boot
            Task { await state.perform(action, on: device) }
        } label: {
            Image(systemName: device.status == .booted ? "power" : "play.fill")
                .font(.caption)
                .foregroundStyle(device.status == .booted ? .red : .green)
                .padding(6)
                .background((device.status == .booted ? Color.red : Color.green).opacity(0.1), in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(state.isProcessingAction)
        .help(device.status == .booted ? "Shutdown" : "Boot")
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
            Task { await state.perform(.wipeData, on: device) }
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
            Task { await state.perform(.coldBoot, on: device) }
        }
    }
}

// MARK: - Section Header

struct SectionHeader<Trailing: View>: View {
    let title: String
    let count: Int
    @ViewBuilder let trailing: Trailing

    init(title: String, count: Int, @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.count = count
        self.trailing = trailing()
    }

    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            Text("\(count)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 5)
                .padding(.vertical, 1)
                .background(.quaternary.opacity(0.4), in: Capsule())

            Spacer()
            trailing
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 4)
    }
}
