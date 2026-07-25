import Foundation

public final class NetworkSnifferUseCase: Sendable {
    private let proxyServer: NetworkSnifferProtocol
    
    public init(proxyServer: NetworkSnifferProtocol) {
        self.proxyServer = proxyServer
    }
    
    public func start(port: UInt16 = 8080) async throws -> AsyncStream<NetworkTraffic> {
        return try await proxyServer.startProxy(port: port)
    }
    
    public func stop() async {
        await proxyServer.stopProxy()
    }
}
