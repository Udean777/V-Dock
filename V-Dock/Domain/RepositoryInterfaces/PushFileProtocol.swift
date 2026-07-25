import Foundation

enum PushFileError: LocalizedError {
    case deviceNotFound
    case fileTransferFailed(String)
    case unsupportedPlatform
    case containerNotFound
    
    var errorDescription: String? {
        switch self {
        case .deviceNotFound: return "Device not found."
        case .fileTransferFailed(let msg): return "Transfer failed: \(msg)"
        case .unsupportedPlatform: return "Unsupported platform."
        case .containerNotFound: return "Container not found."
        }
    }
}

protocol PushFileProtocol: Sendable {
    func pushMedia(to device: Device, filePath: URL) async throws
    func pushDocument(to device: Device, filePath: URL, bundleId: String?) async throws
}
