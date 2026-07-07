import Foundation

protocol MediaCaptureProtocol: Sendable {
    func takeScreenshot(device: Device, destination: URL) async throws
    func startRecording(device: Device, destination: URL) async throws
    func stopRecording(device: Device) async throws
}
