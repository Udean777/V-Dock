import Foundation

protocol DeviceRepositoryProtocol: Sendable {
    func fetchAll() async throws -> [Device]
}
