import Foundation

enum DevicePlatform: String, Sendable {
    case ios
    case android
}

enum DeviceStatus: String, Sendable {
    case booted
    case shutdown
    case booting
}

enum ConnectionType: String, Sendable {
    case local
    case wireless
}

struct Device: Identifiable, Sendable {
    let id: String
    let name: String
    let platform: DevicePlatform
    let status: DeviceStatus
    var connectionType: ConnectionType = .local
}
