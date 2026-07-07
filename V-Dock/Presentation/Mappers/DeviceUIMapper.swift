import Foundation

struct DeviceUIModel: Identifiable, Sendable {
    let id: String
    let name: String
    let platformLabel: String
    let statusLabel: String
    let isRunning: Bool
}

enum DeviceUIMapper {
    static func map(_ device: Device) -> DeviceUIModel {
        DeviceUIModel(
            id: device.id,
            name: device.name,
            platformLabel: device.platform.rawValue.uppercased(),
            statusLabel: device.status.rawValue.capitalized,
            isRunning: device.status == .booted
        )
    }
}
