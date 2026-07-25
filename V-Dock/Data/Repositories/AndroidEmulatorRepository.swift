import Foundation

final class AndroidEmulatorRepository: DeviceRepositoryProtocol {
    private let shell: ShellExecutor
    
    init(shell: ShellExecutor) {
        self.shell = shell
    }
    
    func fetchAll() async throws -> [Device] {
        guard let sdkPath = resolveSDKPath() else {
            return []
        }
        let emulatorPath = "\(sdkPath)/emulator/emulator"
        let output = try await shell.run(emulatorPath, args: ["-list-avds"])
        let names = output
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        let runningNames = await runningAVDNames()
        
        return names.map { name in
            Device(
                id: String(name),
                name: String(name),
                platform: .android,
                status: runningNames.contains(name) ? .booted : .shutdown
            )
        }
    }
    
    private func runningAVDNames() async -> Set<String> {
        guard let output = try? await shell.run("/bin/ps", args: ["-eo", "args"]) else { return [] }
        return Set(output.split(separator: "\n").compactMap { line in
            guard ["qemu", "emulator"].contains(where: { line.contains($0) }) else { return nil }
            guard let range = line.range(of: "-avd ") else { return nil }
            return line[range.upperBound...].split(separator: " ").first.map(String.init)
        })
    }
    
    func resolveSDKPath() -> String? {
        let candidates = [
            UserDefaults.standard.string(forKey: "androidSDKPath"),
            ProcessInfo.processInfo.environment["ANDROID_HOME"],
            ProcessInfo.processInfo.environment["ANDROID_SDK_ROOT"],
            "\(NSHomeDirectory())/Library/Android/sdk",
        ]
        for path in candidates.compactMap({ $0 }) {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        return nil
    }
    
    private var emulatorPath: String? {
        guard let sdkPath = resolveSDKPath() else { return nil }
        return "\(sdkPath)/emulator/emulator"
    }
}

extension AndroidEmulatorRepository: DeviceLifecycleProtocol {
    func boot(device: Device) async throws {
        guard let path = emulatorPath else { return }
        try shell.runDetached(path, args: ["-avd", device.id])
    }
    
    func shutdown(device: Device) async throws {
        _ = try await shell.run("/usr/bin/pkill", args: ["-f", "qemu.*\(device.id)"])
    }
    
    func coldBoot(device: Device) async throws {
        guard let path = emulatorPath else { return }
        try shell.runDetached(path, args: ["-avd", device.id, "-no-snapshot-load"])
    }
    
    func wipeData(device: Device) async throws {
        guard let path = emulatorPath else { return }
        _ = try? await shell.run("/usr/bin/pkill", args: ["-f", "qemu.*\(device.id)"])
        try await Task.sleep(nanoseconds: 2_000_000_000)
        try shell.runDetached(path, args: ["-avd", device.id, "-wipe-data"])
    }
    
    func forceKill(device: Device) async throws {
        _ = try await shell.run("/usr/bin/pkill", args: ["-9", "-f", "qemu.*\(device.id)"])
    }
}

extension AndroidEmulatorRepository: MediaCaptureProtocol {
    var adbPath: String? {
        guard let sdkPath = resolveSDKPath() else { return nil }
        return "\(sdkPath)/platform-tools/adb"
    }

    /// Maps an AVD name (e.g. "Pixel_8_Pro") to its ADB transport serial (e.g. "emulator-5554").
    /// Queries every running emulator via `adb -s <serial> emu avd name` and returns the match.
    func adbSerial(for avdName: String) async -> String? {
        guard let adb = adbPath else { return nil }
        // Get all connected serials
        guard let devicesOutput = try? await shell.run(adb, args: ["devices"]) else { return nil }
        let serials = devicesOutput
            .split(separator: "\n")
            .dropFirst() // skip "List of devices attached"
            .compactMap { line -> String? in
                let parts = line.split(separator: "\t")
                guard parts.count == 2, parts[1].trimmingCharacters(in: .whitespaces) == "device" else { return nil }
                return String(parts[0])
            }

        for serial in serials {
            if let name = try? await shell.run(adb, args: ["-s", serial, "emu", "avd", "name"]) {
                // Output uses \r\n line endings: "Pixel_8_Pro\r\nOK\r\n"
                let firstLine = name
                    .components(separatedBy: .newlines)
                    .first?
                    .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                if firstLine == avdName {
                    return serial
                }
            }
        }
        return nil
    }
    
    func takeScreenshot(device: Device, destination: URL) async throws {
        guard let adb = adbPath else { return }
        let s = await adbSerial(for: device.id) ?? "-e"
        let flag = s == "-e" ? ["-e"] : ["-s", s]
        _ = try await shell.run(adb, args: flag + ["shell", "screencap", "-p", "/sdcard/screen.png"])
        _ = try await shell.run(adb, args: flag + ["pull", "/sdcard/screen.png", destination.path])
        _ = try await shell.run(adb, args: flag + ["shell", "rm", "/sdcard/screen.png"])
    }

    func startRecording(device: Device, destination: URL) async throws {
        guard let adb = adbPath else { return }
        let s = await adbSerial(for: device.id) ?? "-e"
        let flag = s == "-e" ? ["-e"] : ["-s", s]
        let processID = "record_android_\(device.id)"
        try await shell.spawn(id: processID, executable: adb, args: flag + ["shell", "screenrecord", "/sdcard/vid.mp4"])
    }

    func stopRecording(device: Device) async throws {
        guard let adb = adbPath else { return }
        let s = await adbSerial(for: device.id) ?? "-e"
        let flag = s == "-e" ? ["-e"] : ["-s", s]
        let processID = "record_android_\(device.id)"
        await shell.terminate(id: processID)

        try await Task.sleep(nanoseconds: 2_000_000_000)

        let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        let dest = desktop.appendingPathComponent("V-Dock_Android_\(Int(Date().timeIntervalSince1970)).mp4").path
        _ = try? await shell.run(adb, args: flag + ["pull", "/sdcard/vid.mp4", dest])
        _ = try? await shell.run(adb, args: flag + ["shell", "rm", "/sdcard/vid.mp4"])
    }
}

extension AndroidEmulatorRepository: QuickTogglesProtocol {
    func setDarkMode(device: Device, isDark: Bool) async throws {
        guard let adb = adbPath else { return }
        let s = await adbSerial(for: device.id) ?? "-e"
        let flag = s == "-e" ? ["-e"] : ["-s", s]
        _ = try await shell.run(adb, args: flag + ["shell", "cmd", "uimode", "night", isDark ? "yes" : "no"])
    }
}

extension AndroidEmulatorRepository: LogStreamProtocol {
    func streamLogs(for device: Device) -> AsyncStream<String> {
        guard let adb = adbPath else { return AsyncStream { $0.finish() } }
        let processID = "log_android_\(device.id)"
        // streamLogs is sync — fall back to -e (single emulator) or best effort with AVD name
        // A full fix would require making the protocol async; -e works for the common single-emulator case.
        return shell.stream(id: processID, executable: adb, args: ["-e", "logcat", "-v", "brief"])
    }
}

