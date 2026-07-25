import Foundation

final class IOSSimulatorPushFileRepository: PushFileProtocol {
    private let executor: ShellExecutor
    
    init(executor: ShellExecutor) {
        self.executor = executor
    }
    
    func pushMedia(to device: Device, filePath: URL) async throws {
        guard device.platform == .ios else { throw PushFileError.unsupportedPlatform }
        
        do {
            _ = try await executor.run("/usr/bin/xcrun", args: ["simctl", "addmedia", device.id, filePath.path])
        } catch let ShellError.nonZeroExit(_, stderr) {
            throw PushFileError.fileTransferFailed(stderr)
        } catch {
            throw PushFileError.fileTransferFailed(error.localizedDescription)
        }
    }
    
    func pushDocument(to device: Device, filePath: URL, bundleId: String?) async throws {
        guard device.platform == .ios else { throw PushFileError.unsupportedPlatform }
        
        do {
            let dataPathStr = try await executor.run("/usr/bin/xcrun", args: ["simctl", "getenv", device.id, "SIMULATOR_SHARED_RESOURCES_DIRECTORY"]).trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Find the com.apple.FileProvider.LocalStorage app group container which corresponds to "On My iPhone"
            let findCmd = "find \"\(dataPathStr)/Containers/Shared/AppGroup\" -maxdepth 2 -name \".com.apple.mobile_container_manager.metadata.plist\" -exec grep -l \"com.apple.FileProvider.LocalStorage\" {} + | head -n 1 | xargs dirname"
            
            let groupPathStr = try await executor.run("/bin/bash", args: ["-c", findCmd]).trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard !groupPathStr.isEmpty else {
                throw PushFileError.fileTransferFailed("Could not locate On My iPhone storage container.")
            }
            
            let containerURL = URL(fileURLWithPath: groupPathStr).appendingPathComponent("File Provider Storage")
            
            // Create folder if it doesn't exist
            if !FileManager.default.fileExists(atPath: containerURL.path) {
                try FileManager.default.createDirectory(at: containerURL, withIntermediateDirectories: true, attributes: nil)
            }
            
            let destinationURL = containerURL.appendingPathComponent(filePath.lastPathComponent)
            
            // Overwrite if exists
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            
            try FileManager.default.copyItem(at: filePath, to: destinationURL)
            
        } catch let ShellError.nonZeroExit(_, stderr) {
            throw PushFileError.fileTransferFailed(stderr)
        } catch {
            throw PushFileError.fileTransferFailed(error.localizedDescription)
        }
    }
}
