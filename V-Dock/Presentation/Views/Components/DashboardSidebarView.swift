import SwiftUI

struct DashboardSidebarView: View {
    @Environment(AppState.self) var state

    private var bootedCount: Int { state.devices.filter { $0.status == .booted }.count }
    private var shutdownCount: Int { state.devices.filter { $0.status == .shutdown }.count }
    private var iosCount: Int { state.devices.filter { $0.platform == .ios }.count }
    private var androidCount: Int { state.devices.filter { $0.platform == .android }.count }

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
                StatRow(label: "Running", value: "\(bootedCount)", color: .green)
                StatRow(label: "iOS", value: "\(iosCount)", color: .blue)
                StatRow(label: "Android", value: "\(androidCount)", color: .green)
            }

            Section("Quick Actions") {
                Button("Boot All", systemImage: "play.fill") {
                    Task { await bulkAction(.boot) }
                }
                .disabled(shutdownCount == 0)

                Button("Shutdown All", systemImage: "stop.fill") {
                    Task { await bulkAction(.shutdown) }
                }
                .disabled(bootedCount == 0)

                Button("Refresh", systemImage: "arrow.clockwise") {
                    Task { await state.refresh() }
                }
                .keyboardShortcut("r", modifiers: .command)
            }
            .buttonStyle(.plain)
        }
        .listStyle(.sidebar)
    }

    private func bulkAction(_ action: DeviceAction) async {
        let targetStatus: DeviceStatus = action == .boot ? .shutdown : .booted
        for device in state.devices where device.status == targetStatus {
            await state.perform(action, on: device)
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
