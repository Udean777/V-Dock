import Foundation

final class MediaCaptureUseCase: Sendable {
    private let iosCapture: MediaCaptureProtocol
    private let androidCapture: MediaCaptureProtocol
    
    init(iosCapture: MediaCaptureProtocol, androidCapture: MediaCaptureProtocol) {
        self.iosCapture = iosCapture
        self.androidCapture = androidCapture
    }
    
    private func handler(for device: Device) -> MediaCaptureProtocol {
        switch device.platform {
        case .ios: iosCapture
        case .android: androidCapture
        }
    }
    
    func takeScreenshot(device: Device, destination: URL) async throws {
        try await handler(for: device).takeScreenshot(device: device, destination: destination)
    }
    
    func startRecording(device: Device, destination: URL) async throws {
        try await handler(for: device).startRecording(device: device, destination: destination)
    }
    
    func stopRecording(device: Device) async throws {
        try await handler(for: device).stopRecording(device: device)
    }
}
