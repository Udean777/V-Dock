import SwiftUI

struct DashboardSidebarView: View {
    @Environment(AppState.self) var state
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    if let appIcon = NSImage(named: NSImage.applicationIconName) {
                        Image(nsImage: appIcon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 48, height: 48)
                    } else {
                        Image(systemName: "display")
                            .font(.title)
                            .foregroundStyle(.tint)
                    }
                    Text("V-Dock")
                        .font(.headline)
                    Text("Device Manager")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
                .listRowBackground(Color.clear)
            }
            
            Section("Summary") {
                StatRow(label: "Total", value: "\(state.devices.count)")
                StatRow(label: "Running", value: "\(state.devices.filter { $0.status == .booted }.count)", color: .green)
                StatRow(label: "iOS", value: "\(state.devices.filter { $0.platform == .ios }.count)", color: .blue)
                StatRow(label: "Android", value: "\(state.devices.filter { $0.platform == .android }.count)", color: .green)
            }
            
            Section("Quick Actions") {
                Button {
                    Task { await bootAll() }
                } label: {
                    Label("Boot All", systemImage: "play.fill")
                }
                .disabled(state.devices.filter { $0.status == .shutdown }.isEmpty)
                
                Button {
                    Task { await shutdownAll() }
                } label: {
                    Label("Shutdown All", systemImage: "stop.fill")
                }
                .disabled(state.devices.filter { $0.status == .booted }.isEmpty)
                
                Button {
                    Task { await state.refresh() }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .keyboardShortcut("r", modifiers: .command)
            }
            .buttonStyle(.plain)
        }
        .listStyle(.sidebar)
    }
    
    private func bootAll() async {
        for device in state.devices where device.status == .shutdown {
            await state.perform(.boot, on: device)
        }
    }
    
    private func shutdownAll() async {
        for device in state.devices where device.status == .booted {
            await state.perform(.shutdown, on: device)
        }
    }
}

private struct StatRow: View {
    let label: String
    let value: String
    var color: Color = .primary
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .foregroundStyle(color)
                .fontWeight(.medium)
        }
        .font(.caption)
    }
}
