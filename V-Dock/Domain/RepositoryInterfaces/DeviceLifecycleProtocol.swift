import Foundation

protocol DeviceLifecycleProtocol: Sendable {
    func boot(device: Device) async throws
    func shutdown(device: Device) async throws
    func coldBoot(device: Device) async throws
    func wipeData(device: Device) async throws
    func forceKill(device: Device) async throws
}
