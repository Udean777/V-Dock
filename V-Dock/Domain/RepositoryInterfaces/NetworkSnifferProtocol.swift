import Foundation

public protocol NetworkSnifferProtocol: Sendable {
    func startProxy(port: UInt16) async throws -> AsyncStream<NetworkTraffic>
    func stopProxy() async
}
