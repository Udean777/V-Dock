import Foundation

final class LogStreamUseCase: Sendable {
    private let iosStream: LogStreamProtocol
    private let androidStream: LogStreamProtocol
    
    init(iosStream: LogStreamProtocol, androidStream: LogStreamProtocol) {
        self.iosStream = iosStream
        self.androidStream = androidStream
    }
    
    private func handler(for device: Device) -> LogStreamProtocol {
        switch device.platform {
        case .ios: iosStream
        case .android: androidStream
        }
    }
    
    func streamLogs(for device: Device) -> AsyncStream<String> {
        handler(for: device).streamLogs(for: device)
    }
}
