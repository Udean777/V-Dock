import Foundation

final class ResourceMonitorUseCase: Sendable {
    private let monitor: ResourceMonitorProtocol

    init(monitor: ResourceMonitorProtocol) {
        self.monitor = monitor
    }

    func execute(bootedDevices: [Device]) async throws -> [String: ResourceUsage] {
        try await monitor.fetchUsage(bootedDevices: bootedDevices)
    }
}
