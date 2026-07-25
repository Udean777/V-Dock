import Foundation

final class NetworkProxyUseCase: Sendable {
    private let androidRepo: NetworkProxyProtocol
    private let iosRepo: NetworkProxyProtocol
    
    init(androidRepo: NetworkProxyProtocol, iosRepo: NetworkProxyProtocol) {
        self.androidRepo = androidRepo
        self.iosRepo = iosRepo
    }
    
    func setProxy(device: Device, host: String, port: Int) async throws {
        switch device.platform {
        case .android:
            try await androidRepo.setProxy(device: device, host: host, port: port)
        case .ios:
            try await iosRepo.setProxy(device: device, host: host, port: port)
        }
    }
    
    func clearProxy(device: Device) async throws {
        switch device.platform {
        case .android:
            try await androidRepo.clearProxy(device: device)
        case .ios:
            try await iosRepo.clearProxy(device: device)
        }
    }
}
