import Foundation

enum DeviceAction: Sendable {
    case boot
    case shutdown
    case coldBoot
    case wipeData
    case forceKill
}
