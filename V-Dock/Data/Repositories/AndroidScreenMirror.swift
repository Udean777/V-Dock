//
//  AndroidScreenMirror.swift
//  V-Dock
//
//  Created by Sajudin on 25/07/26.
//

import Foundation
import CoreGraphics

final class AndroidScreenMirror: ScreenMirrorProtocol, @unchecked Sendable {
    private let shell: ShellExecutor
    private var activeMirrors: [String: Task<Void, Never>] = [:]
    private var continuations: [String: AsyncStream<CGImage>.Continuation] = [:]
    
    init(shell: ShellExecutor) {
        self.shell = shell
    }
    
    func startMirror(device: Device) -> AsyncStream<CGImage> {
        AsyncStream { continuation in
            let id = device.id
            continuations[id] = continuation
            
            activeMirrors[id]  = Task { [weak self] in
                guard let adb = self?.resolveADBPath() else {
                    continuation.finish()
                    return
                }
                
                while !Task.isCancelled {
                    do {
                        if let data = try await self?.shell.runRaw(adb, args: ["-s", device.id, "exec-out", "screencap", "-p"]), let image = CGImageFromPNG(data) {
                            continuation.yield(image)
                        }
                    } catch {
                        break
                    }
                    
                    try? await Task.sleep(nanoseconds: 200_000_000)
                }
                
                continuation.finish()
            }
            
            continuation.onTermination = { @Sendable [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.activeMirrors[id]?.cancel()
                    self?.activeMirrors[id] = nil
                    self?.continuations[id] = nil
                }
            }
        }
    }
    
    func stopMirror(device: Device) {
        activeMirrors[device.id]?.cancel()
        activeMirrors[device.id] = nil
        continuations[device.id]?.finish()
        continuations[device.id] = nil
    }
    
    func sendTouch(device: Device, x: Int, y: Int, action: TouchAction) {
        let adbAction: String = switch action {
        case .down: "0"
        case .up: "1"
        case .move: "2"
        }
        sendInput(device: device, cmd: "tap \(x) \(y)", extra: adbAction)
    }
    
    
    func sendSwipe(device: Device, x1: Int, y1: Int, x2: Int, y2: Int, durationMs: Int) {
        sendInput(device: device, cmd: "swipe \(x1) \(y1) \(x2) \(y2) \(durationMs)")
    }
    
    func sendKey(device: Device, key: String) {
        sendInput(device: device, cmd: "keyevent \(key)")
    }
    
    private func sendInput(device: Device, cmd: String, extra: String = "") {
        guard let adb = resolveADBPath() else { return }
        Task {
            try? await shell.run(adb, args: ["-s", device.id, "shell", "input", cmd])
        }
    }
    
    
    private func resolveADBPath() -> String? {
        let sdk = resolveSDKPath() ?? ""
        return [
            "\(sdk)/platform-tools/adb",
            "/usr/local/bin/adb",
            "/opt/homebrew/bin/adb",
        ].first { FileManager.default.fileExists(atPath: $0) }
    }
    
    
    private func resolveSDKPath() -> String? {
        let candidates = [
            UserDefaults.standard.string(forKey: "androidSDKPath"),
            ProcessInfo.processInfo.environment["ANDROID_HOME"],
            ProcessInfo.processInfo.environment["ANDROID_SDK_ROOT"],
            "\(NSHomeDirectory())/Library/Android/sdk",
        ]
        
        return candidates.compactMap({ $0 }).first { FileManager.default.fileExists(atPath: $0) }
    }
}

private func CGImageFromPNG(_ data: Data) -> CGImage? {
    guard let provider = CGDataProvider(data: data as CFData) else {return nil}
    
    return CGImage(pngDataProviderSource: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
}
