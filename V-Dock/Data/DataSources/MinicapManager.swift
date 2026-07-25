import Foundation
import CoreGraphics

final class MinicapManager {
    private let shell: ShellExecutor
    private var activeTasks: [String: Task<Void, Never>] = [:]

    init(shell: ShellExecutor) {
        self.shell = shell
    }

    func resolveADBPath() -> String? {
        let sdk = resolveSDKPath() ?? ""
        return ["\(sdk)/platform-tools/adb", "/usr/local/bin/adb", "/opt/homebrew/bin/adb"]
            .first { FileManager.default.fileExists(atPath: $0) }
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

    func streamFrames(device: Device) -> AsyncStream<CGImage> {
        AsyncStream { continuation in
            let id = device.id
            activeTasks[id] = Task {
                guard let adb = resolveADBPath() else {
                    continuation.finish(); return
                }

                let arch = ((try? await shell.run(adb, args: ["-s", id, "shell", "getprop", "ro.product.cpu.abi"])) ?? "arm64-v8a")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let sdk = ((try? await shell.run(adb, args: ["-s", id, "shell", "getprop", "ro.build.version.sdk"])) ?? "34")
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                let displayInfo = try? await shell.run(adb, args: ["-s", id, "shell", "wm", "size"])
                let dimStr = displayInfo?.trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "Physical size: ", with: "")
                    .split(separator: "x")
                guard dimStr?.count == 2,
                      let w = dimStr?[0].trimmingCharacters(in: .whitespaces).split(separator: "\n").first.flatMap({ Int($0) }),
                      let h = dimStr?[1].trimmingCharacters(in: .whitespaces).split(separator: "\n").first.flatMap({ Int($0) }) else {
                    continuation.finish(); return
                }

                let minicapDir = "\(NSHomeDirectory())/Library/Application Support/V-Dock/minicap"

                // Push binary
                let localBin = "\(minicapDir)/\(arch)/minicap"
                guard FileManager.default.fileExists(atPath: localBin) else {
                    // Fall back to screencap polling
                    await runScreencapFallback(device: device, adb: adb, continuation: continuation)
                    return
                }
                _ = try? await shell.run(adb, args: ["-s", id, "push", localBin, "/data/local/tmp/minicap"])
                _ = try? await shell.run(adb, args: ["-s", id, "shell", "chmod", "0755", "/data/local/tmp/minicap"])

                // Push .so — exact SDK match only; mismatched SDK causes link errors
                let sdkNum = Int(sdk) ?? 0
                let so = "\(minicapDir)/android-\(sdkNum)/\(arch)/minicap.so"
                guard FileManager.default.fileExists(atPath: so) else {
                    await runScreencapFallback(device: device, adb: adb, continuation: continuation)
                    return
                }
                _ = try? await shell.run(adb, args: ["-s", id, "push", so, "/data/local/tmp/minicap.so"])

                _ = try? await shell.run(adb, args: ["-s", id, "shell", "pkill", "-9", "minicap"])
                try? await Task.sleep(nanoseconds: 200_000_000)

                let projection = "\(w)x\(h)@\(w)x\(h)/0"
                let runCmd = "LD_LIBRARY_PATH=/data/local/tmp /data/local/tmp/minicap -P '\(projection)'"
                _ = try? await shell.spawn(id: "minicap_\(id)", executable: adb, args: ["-s", id, "shell", runCmd])
                try? await Task.sleep(nanoseconds: 500_000_000)

                _ = try? await shell.run(adb, args: ["-s", id, "forward", "tcp:1313", "localabstract:minicap"])

                if !(await connectSocketWithTimeout()) {
                    // minicap crashed at link — fall back to polling
                    await runScreencapFallback(device: device, adb: adb, continuation: continuation)
                } else {
                    await readFrames(continuation: continuation)
                }
            }
        }
    }

    private func runScreencapFallback(device: Device, adb: String, continuation: AsyncStream<CGImage>.Continuation) async {
        while !Task.isCancelled {
            if let data = try? await shell.runRaw(adb, args: ["-s", device.id, "exec-out", "screencap"]),
               let img = rawScreencapToCGImage(data) {
                continuation.yield(img)
            }
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
    }

    private func readFrames(continuation: AsyncStream<CGImage>.Continuation) async {
        guard let sock = try? await connectSocket() else { return }

        // Read 24-byte global header
        var header = [UInt8](repeating: 0, count: 24)
        guard readAll(sock, &header, 24) else { close(sock); return }

        // Read frames
        var sizeBuf = [UInt8](repeating: 0, count: 4)
        while !Task.isCancelled {
            guard readAll(sock, &sizeBuf, 4) else { break }
            let frameSize = sizeBuf.withUnsafeBytes { $0.loadUnaligned(as: UInt32.self) }
            guard frameSize > 0, frameSize < 50_000_000 else { continue }

            var frameBuf = [UInt8](repeating: 0, count: Int(frameSize))
            guard readAll(sock, &frameBuf, Int(frameSize)) else { break }

            if let img = jpegToCGImage(Data(frameBuf)) {
                continuation.yield(img)
            }
        }
        close(sock)
    }

    private func readAll(_ fd: Int32, _ buf: inout [UInt8], _ count: Int) -> Bool {
        var total = 0
        while total < count {
            let n = Darwin.read(fd, &buf[total], count - total)
            if n <= 0 { return false }
            total += n
        }
        return true
    }

    private func connectSocket() async throws -> Int32 {
        try await Task.detached {
            let sock = socket(AF_INET, SOCK_STREAM, 0)
            guard sock >= 0 else { throw MinicapError.connectFailed }
            var val: Int32 = 1
            setsockopt(sock, SOL_SOCKET, SO_NOSIGPIPE, &val, socklen_t(MemoryLayout<Int32>.size))
            // 2s connect timeout so we don't hang when minicap crashed
            var tv = timeval(tv_sec: 2, tv_usec: 0)
            setsockopt(sock, SOL_SOCKET, SO_SNDTIMEO, &tv, socklen_t(MemoryLayout<timeval>.size))
            var addr = sockaddr_in()
            addr.sin_family = sa_family_t(AF_INET)
            addr.sin_port = CFSwapInt16HostToBig(1313)
            addr.sin_addr.s_addr = inet_addr("127.0.0.1")
            let result = withUnsafePointer(to: &addr) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    Darwin.connect(sock, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
                }
            }
            guard result == 0 else { close(sock); throw MinicapError.connectFailed }
            return sock
        }.value
    }

    private func connectSocketWithTimeout() async -> Bool {
        (try? await connectSocket()) != nil
    }

    func stop(device: Device) {
        activeTasks[device.id]?.cancel()
        activeTasks[device.id] = nil
        Task {
            guard let adb = resolveADBPath() else { return }
            _ = try? await shell.run(adb, args: ["-s", device.id, "forward", "--remove", "tcp:1313"])
            _ = try? await shell.run(adb, args: ["-s", device.id, "shell", "pkill", "-9", "minicap"])
        }
    }
}

private func jpegToCGImage(_ data: Data) -> CGImage? {
    guard let provider = CGDataProvider(data: data as CFData) else { return nil }
    return CGImage(jpegDataProviderSource: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
}

enum MinicapError: Error {
    case connectFailed
}

private func rawScreencapToCGImage(_ data: Data) -> CGImage? {
    guard data.count > 12 else { return nil }
    let w = data.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: 0, as: UInt32.self) }
    let h = data.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: 4, as: UInt32.self) }
    let width = Int(UInt32(littleEndian: w))
    let height = Int(UInt32(littleEndian: h))
    let pixelData = data.dropFirst(12)
    guard pixelData.count >= width * height * 4 else { return nil }
    let provider = CGDataProvider(data: pixelData as CFData)!
    return CGImage(
        width: width, height: height,
        bitsPerComponent: 8, bitsPerPixel: 32,
        bytesPerRow: width * 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
        provider: provider, decode: nil, shouldInterpolate: false,
        intent: .defaultIntent
    )
}