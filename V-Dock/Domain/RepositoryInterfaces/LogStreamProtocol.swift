import Foundation

protocol LogStreamProtocol: Sendable {
    func streamLogs(for device: Device) -> AsyncStream<String>
}
