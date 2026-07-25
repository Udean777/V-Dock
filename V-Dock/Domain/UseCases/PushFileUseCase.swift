import Foundation
import UniformTypeIdentifiers

final class PushFileUseCase: Sendable {
    private let androidRepo: PushFileProtocol
    private let iosRepo: PushFileProtocol
    
    init(androidRepo: PushFileProtocol, iosRepo: PushFileProtocol) {
        self.androidRepo = androidRepo
        self.iosRepo = iosRepo
    }
    
    func execute(device: Device, filePath: URL, bundleId: String? = nil) async throws {
        let repo = device.platform == .ios ? iosRepo : androidRepo
        
        if isMediaFile(filePath) {
            do {
                try await repo.pushMedia(to: device, filePath: filePath)
            } catch {
                // Fallback to document push if media push fails (e.g. unsupported formats like .webp on iOS)
                try await repo.pushDocument(to: device, filePath: filePath, bundleId: bundleId)
            }
        } else {
            try await repo.pushDocument(to: device, filePath: filePath, bundleId: bundleId)
        }
    }
    
    private func isMediaFile(_ url: URL) -> Bool {
        guard let type = UTType(filenameExtension: url.pathExtension) else { return false }
        return type.conforms(to: .image) || type.conforms(to: .audiovisualContent)
    }
}
