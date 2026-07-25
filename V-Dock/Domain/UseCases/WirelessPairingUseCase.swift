import Foundation

struct DiscoveredService: Sendable, Identifiable {
    let id: String
    let serviceName: String
    let host: String
    let port: Int
}

final class WirelessPairingUseCase: Sendable {
    private let wirelessRepo: WirelessADBRepository

    init(wirelessRepo: WirelessADBRepository) {
        self.wirelessRepo = wirelessRepo
    }

    func pairAndConnect(host: String, port: Int, code: String) async throws {
        try await wirelessRepo.pair(host: host, port: port, code: code)
        try await wirelessRepo.connect(host: host, port: port)
    }

    func connect(host: String, port: Int) async throws {
        try await wirelessRepo.connect(host: host, port: port)
    }

    func disconnect(host: String, port: Int) async throws {
        try await wirelessRepo.disconnect(host: host, port: port)
    }

    func discoverServices() async throws -> [DiscoveredService] {
        let services = try await wirelessRepo.discoverMDNS()
        return services.enumerated().map { i, svc in
            DiscoveredService(id: "mdns-\(i)", serviceName: svc.serviceName, host: svc.host, port: svc.port)
        }
    }
}
