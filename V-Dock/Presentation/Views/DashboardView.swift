import SwiftUI

struct DashboardView: View {
    @Environment(AppState.self) var state
    
    var body: some View {
        NavigationSplitView {
            DashboardSidebarView()
                .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 260)
        } detail: {
            DeviceListView()
                .navigationTitle("Devices")
        }
        .toolbar {
            ToolbarItem {
                if state.isRefreshing {
                    ProgressView()
                        .controlSize(.small)
                }
            }
        }
        .task {
            NSApp.activate(ignoringOtherApps: true)
            await state.refresh()
        }
        .task {
            while !Task.isCancelled {
                await state.refreshResources()
                try? await Task.sleep(nanoseconds: 5_000_000_000)
            }
        }
        .alert("Action Failed", isPresented: Binding(
            get: { state.actionError != nil },
            set: { if !$0 { state.actionError = nil } }
        )) {
            Button("OK", role: .cancel) { state.actionError = nil }
        } message: {
            Text(state.actionError ?? "")
        }
    }
}

private struct DeviceListView: View {
    @Environment(AppState.self) var state
    @Environment(\.openWindow) private var openWindow
    @State private var iosExpanded = true
    @State private var androidExpanded = true
    
    private var iosDevices: [Device] {
        state.devices.filter { $0.platform == .ios }
    }
    
    private var androidDevices: [Device] {
        state.devices.filter { $0.platform == .android }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if let err = state.refreshError {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark.octagon.fill")
                            .foregroundStyle(.red)
                        Text(err)
                            .font(.caption)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.red.opacity(0.08))
                    .clipShape(.rect(cornerRadius: 8))
                    .padding()
                }

                if !state.hasAndroidSDK && androidDevices.isEmpty {
                    errorBanner
                }
                
                platformSection(
                    icon: "iphone",
                    title: "iOS Simulators",
                    subtitle: "\(iosDevices.count) available, \(iosDevices.filter { $0.status == .booted }.count) running",
                    accent: .blue,
                    devices: iosDevices,
                    isExpanded: $iosExpanded
                )
                
                Divider()
                    .padding(.horizontal)
                
                platformSection(
                    icon: "smartphone",
                    title: "Android Emulators",
                    subtitle: state.hasAndroidSDK
                    ? "\(androidDevices.count) available, \(androidDevices.filter { $0.status == .booted }.count) running"
                    : "SDK path not set",
                    accent: .green,
                    devices: androidDevices,
                    isExpanded: $androidExpanded
                )
            }
        }
        .scrollIndicators(.hidden)
    }
    
    private var errorBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            Text("Android SDK not found. Simulators and emulators may not be fully detected.")
                .font(.caption)
            Spacer()
            Button("Configure") {
                openWindow(id: "settings")
                NSApp.activate(ignoringOtherApps: true)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(12)
        .background(.yellow.opacity(0.08))
        .clipShape(.rect(cornerRadius: 8))
        .padding()
    }
    
    private func platformSection(icon: String, title: String, subtitle: String, accent: Color, devices: [Device], isExpanded: Binding<Bool>) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Button {
                    withAnimation(.smooth(duration: 0.2)) {
                        isExpanded.wrappedValue.toggle()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: isExpanded.wrappedValue ? "chevron.down" : "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Image(systemName: icon)
                            .font(.title3)
                            .foregroundStyle(accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(title)
                                .font(.headline)
                            Text(subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                if !devices.isEmpty {
                    let booted = devices.filter { $0.status == .booted }
                    let shutdown = devices.filter { $0.status == .shutdown }
                    HStack(spacing: 4) {
                        if !booted.isEmpty {
                            Button {
                                Task { await shutdownAll(devices: booted) }
                            } label: {
                                Image(systemName: "stop.fill")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                            .help("Shutdown all \(title)")
                        }
                        if !shutdown.isEmpty {
                            Button {
                                Task { await bootAll(devices: shutdown) }
                            } label: {
                                Image(systemName: "play.fill")
                                    .foregroundStyle(.green)
                            }
                            .buttonStyle(.plain)
                            .help("Boot all \(title)")
                        }
                    }
                    .font(.caption)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            
            if isExpanded.wrappedValue {
                if devices.isEmpty {
                    Text("No devices found")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 24)
                } else {
                    ForEach(devices) { device in
                        VStack(spacing: 0) {
                            DeviceCardView(
                                device: device,
                                isPinned: state.pinnedIDs.contains(device.id),
                                resourceUsage: state.resourceUsage[device.id],
                                onTogglePin: { state.togglePin(for: device) },
                                onPerformAction: { await state.perform($0, on: device) }
                            )
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            if device.id != devices.last?.id {
                                Divider()
                                    .padding(.leading, 44)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func bootAll(devices: [Device]) async {
        for device in devices {
            await state.perform(.boot, on: device)
        }
    }
    
    private func shutdownAll(devices: [Device]) async {
        for device in devices {
            await state.perform(.shutdown, on: device)
        }
    }
}
