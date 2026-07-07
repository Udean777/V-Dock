import Foundation

final class SimulatorRepository: DeviceRepositoryProtocol {
    private let shell: ShellExecutor
    
    init(shell: ShellExecutor) {
        self.shell = shell
    }
    
    func fetchAll() async throws -> [Device] {
        let output = try await shell.run(
            "/usr/bin/xcrun",
            args: ["simctl", "list", "devices", "--json"]
        )
        let data = Data(output.utf8)
        let dto = try JSONDecoder().decode(SimCtlDTO.self, from: data)
        return dto.devices.values
            .flatMap { $0 }
            .filter { $0.isAvailable }
            .map { dtoDevice in
                Device(
                    id: dtoDevice.udid,
                    name: dtoDevice.name,
                    platform: .ios,
                    status: dtoDevice.state == "Booted" ? .booted : .shutdown
                )
            }
    }
}

extension SimulatorRepository: DeviceLifecycleProtocol {
    func boot(device: Device) async throws {
        _ = try await shell.run("/usr/bin/xcrun", args: ["simctl", "boot", device.id])
        try shell.runDetached("/usr/bin/open", args: ["-a", "Simulator"])
        _ = try? await shell.run("/usr/bin/xcrun", args: ["simctl", "launch", device.id, "com.apple.springboard"])
    }
    
    func shutdown(device: Device) async throws {
        _ = try await shell.run("/usr/bin/xcrun", args: ["simctl", "shutdown", device.id])
    }
    
    func coldBoot(device: Device) async throws {
        _ = try? await shell.run("/usr/bin/xcrun", args: ["simctl", "shutdown", device.id])        

        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        _ = try await shell.run("/usr/bin/xcrun", args: ["simctl", "boot", device.id])
        try shell.runDetached("/usr/bin/open", args: ["-a", "Simulator"])
    }
    
    func wipeData(device: Device) async throws {
        _ = try await shell.run("/usr/bin/xcrun", args: ["simctl", "erase", device.id])
    }
    
    func forceKill(device: Device) async throws {
        _ = try await shell.run("/usr/bin/pkill", args: ["-9", "Simulator"])
    }
}

extension SimulatorRepository: MediaCaptureProtocol {
    func takeScreenshot(device: Device, destination: URL) async throws {
        _ = try await shell.run("/usr/bin/xcrun", args: ["simctl", "io", device.id, "screenshot", destination.path])
    }
    
    func startRecording(device: Device, destination: URL) async throws {
        let processID = "record_ios_\(device.id)"
        try await shell.spawn(id: processID, executable: "/usr/bin/xcrun", args: ["simctl", "io", device.id, "recordVideo", "--codec=h264", "--force", destination.path])
    }
    
    func stopRecording(device: Device) async throws {
        let processID = "record_ios_\(device.id)"
        await shell.terminate(id: processID)
    }
}
