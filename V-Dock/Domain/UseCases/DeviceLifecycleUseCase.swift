import Foundation

final class DeviceLifecycleUseCase: Sendable {
    private let iosLifecycle: DeviceLifecycleProtocol
    private let androidLifecycle: DeviceLifecycleProtocol
    
    init(iosLifecycle: DeviceLifecycleProtocol, androidLifecycle: DeviceLifecycleProtocol) {
        self.iosLifecycle = iosLifecycle
        self.androidLifecycle = androidLifecycle
    }
    
    func execute(_ action: DeviceAction, on device: Device) async throws {
        let handler: DeviceLifecycleProtocol = switch device.platform {
        case .ios: iosLifecycle
        case .android: androidLifecycle
        }
        switch action {
        case .boot: try await handler.boot(device: device)
        case .shutdown: try await handler.shutdown(device: device)
        case .coldBoot: try await handler.coldBoot(device: device)
        case .wipeData: try await handler.wipeData(device: device)
        case .forceKill: try await handler.forceKill(device: device)
        }
    }
}
