import Foundation

struct ResourceUsage: Sendable {
    let deviceID: String
    let memoryBytes: UInt64
    let cpuPercent: Double
}

protocol ResourceMonitorProtocol: Sendable {
    func fetchUsage(bootedDevices: [Device]) async throws -> [String: ResourceUsage]
}
