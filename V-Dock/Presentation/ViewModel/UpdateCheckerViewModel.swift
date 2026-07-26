//
//  UpdateCheckerViewModel.swift
//  V-Dock
//
//  Created by Sajudin on 26/07/26.
//

import Foundation
import Observation
import AppKit

@MainActor
@Observable
final class UpdateCheckerViewModel {
    enum UpdateState: Equatable {
        case idle
        case checking
        case upToDate(current: String)
        case updateAvailable(version: String)
        case downloading(progress: Double, version: String)
        case downloaded(path: String, version: String)
        case error(String)
        
        var isWorking: Bool {
            switch self {
            case .checking, .downloading: return true
            default: return false
            }
        }
    }
    
    private(set) var state: UpdateState = .idle
    private let checker: ReleaseChecker
    
    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }
    
    init(checker: ReleaseChecker) {
        self.checker = checker
    }
    
    
    func check() async {
        state = .checking
        
        do {
            let release = try await checker.fetchLatestRelease()
            
            let isNewer = release.version.compare(currentVersion, options: .numeric) == .orderedDescending
            state = isNewer
            ? .updateAvailable(version: release.version)
            : .upToDate(current: currentVersion)
        } catch {
            state = .error(error.localizedDescription)
        }
    }
    
    func downloadAndInstall() async {
        guard case .updateAvailable(let version) = state else {
            return
        }
        
        let downloadURL: URL
        do {
            downloadURL = try await checker.fetchLatestRelease().downloadURL
        } catch {
            state = .error(error.localizedDescription)
            return
        }
        
        state = .downloading(progress: 0, version: version)
        let destURL = FileManager.default.temporaryDirectory.appendingPathComponent("V-Dock-\(version).dmg")
        try? FileManager.default.removeItem(at: destURL)
        
        let delegate = DownloadProgressDelegate()
        delegate.onProgress = { [weak self] pct in
            self?.state = .downloading(progress: pct, version: version)
        }
        
        let session = URLSession(configuration: .ephemeral, delegate: delegate, delegateQueue: .main)
        defer { session.invalidateAndCancel() }
        
        let tmpURL: URL
        do {
            tmpURL = try await withCheckedThrowingContinuation { continuation in
                let task = session.downloadTask(with: downloadURL) { loc, _, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let loc = loc {
                        continuation.resume(returning: loc)
                    } else {
                        continuation.resume(throwing: ReleaseCheckError.invalidResponse)
                    }
                }
                task.resume()
            }
            try FileManager.default.moveItem(at: tmpURL, to: destURL)
        } catch {
            state = .error("Download failed: \(error.localizedDescription)")
            return
        }
        
        state = .downloaded(path: destURL.path, version: version)
        performInstall(path: destURL.path)
    }
    
    func install() {
        guard case .downloaded(let path, _) = state else { return }
        performInstall(path: path)
    }
    
    private func performInstall(path: String) {
        let appBundle = Bundle.main.bundleURL.path
        
        if appBundle.hasPrefix("/Applications/") {
            let script = """
                sleep 1
                hdiutil attach "\(path)" -nobrowse -mountpoint /tmp/vdock-update 2>/dev/null
                cp -R /tmp/vdock-update/V-Dock.app /Applications/
                hdiutil detach /tmp/vdock-update 2>/dev/null
                xattr -cr /Applications/V-Dock.app 2>/dev/null
                codesign --force --deep -s - /Applications/V-Dock.app 2>/dev/null
                rm -f "\(path)"
                open /Applications/V-Dock.app
                """
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/bin/sh")
            proc.arguments = ["-c", script]
            try? proc.run()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NSApp.terminate(nil)
            }
        } else {
            NSWorkspace.shared.open(URL(fileURLWithPath: path))
        }
    }
}

private final class DownloadProgressDelegate: NSObject, URLSessionDownloadDelegate {
    var onProgress: ((Double) -> Void)?
    
    func urlSession(_: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData _: Int64, totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        guard totalBytesExpectedToWrite > 0 else { return }
        onProgress?(Double(totalBytesWritten) / Double(totalBytesExpectedToWrite))
    }
    
    func urlSession(_: URLSession, downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {}
}
