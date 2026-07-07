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
        try shell.runDetached(path, args: ["-avd", device.id, "-wipe-data"])
    }
    
    func forceKill(device: Device) async throws {
        _ = try await shell.run("/usr/bin/pkill", args: ["-9", "-f", "qemu.*\(device.id)"])
    }
}
