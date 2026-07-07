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

struct Device: Identifiable, Sendable {
    let id: String
    let name: String
    let platform: DevicePlatform
    let status: DeviceStatus
}
