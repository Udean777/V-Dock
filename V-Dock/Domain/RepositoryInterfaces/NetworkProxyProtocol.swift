import Foundation

protocol NetworkProxyProtocol: Sendable {
    func setProxy(device: Device, host: String, port: Int) async throws
    func clearProxy(device: Device) async throws
}
