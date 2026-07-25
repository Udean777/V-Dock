import Foundation

final class AndroidPushFileRepository: PushFileProtocol {
    private let executor: ShellExecutor
    
    init(executor: ShellExecutor) {
        self.executor = executor
    }
    
    private var adbPath: String? {
        let candidates = [
            UserDefaults.standard.string(forKey: "androidSDKPath"),
            ProcessInfo.processInfo.environment["ANDROID_HOME"],
            ProcessInfo.processInfo.environment["ANDROID_SDK_ROOT"],
            "\(NSHomeDirectory())/Library/Android/sdk"
        ]
        for path in candidates.compactMap({ $0 }) {
            let fullPath = "\(path)/platform-tools/adb"
            if FileManager.default.fileExists(atPath: fullPath) {
                return fullPath
            }
        }
        // Fallback to homebrew adb if exists
        let brewPath = "/opt/homebrew/bin/adb"
        if FileManager.default.fileExists(atPath: brewPath) {
            return brewPath
        }
        return nil
    }
    
    func pushMedia(to device: Device, filePath: URL) async throws {
        guard device.platform == .android else { throw PushFileError.unsupportedPlatform }
        guard let adb = adbPath else { throw PushFileError.fileTransferFailed("adb executable not found.") }
        
        let destination = "/sdcard/DCIM/\(filePath.lastPathComponent)"
        
        do {
            _ = try await executor.run(adb, args: ["-e", "push", filePath.path, destination])
            
            _ = try await executor.run(adb, args: [
                "-e", "shell", "am", "broadcast",
                "-a", "android.intent.action.MEDIA_SCANNER_SCAN_FILE",
                "-d", "file://\(destination)"
            ])
        } catch let ShellError.nonZeroExit(_, stderr) {
            throw PushFileError.fileTransferFailed(stderr)
        } catch {
            throw PushFileError.fileTransferFailed(error.localizedDescription)
        }
    }
    
    func pushDocument(to device: Device, filePath: URL, bundleId: String?) async throws {
        guard device.platform == .android else { throw PushFileError.unsupportedPlatform }
        guard let adb = adbPath else { throw PushFileError.fileTransferFailed("adb executable not found.") }
        
        let destination = "/sdcard/Download/\(filePath.lastPathComponent)"
        
        do {
            _ = try await executor.run(adb, args: ["-e", "push", filePath.path, destination])
        } catch let ShellError.nonZeroExit(_, stderr) {
            throw PushFileError.fileTransferFailed(stderr)
        } catch {
            throw PushFileError.fileTransferFailed(error.localizedDescription)
        }
    }
}
