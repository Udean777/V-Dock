import Foundation

final class MacOSResourceMonitor: ResourceMonitorProtocol {
    private let shell: ShellExecutor
    
    init(shell: ShellExecutor) {
        self.shell = shell
    }
    
    func fetchUsage(bootedDevices: [Device]) async throws -> [String: ResourceUsage] {
        let output = try await shell.run("/bin/ps", args: ["aux"])
        let lines = output.split(separator: "\n").dropFirst()
        var result: [String: ResourceUsage] = [:]
        
        let iosDeviceIDs = bootedDevices.filter { $0.platform == .ios && $0.status == .booted }.map(\.id)
        
        for line in lines {
            let fields = line.split(separator: " ", omittingEmptySubsequences: true)
            guard fields.count >= 11 else { continue }
            let command = fields[10...].joined(separator: " ")
            let rssStr = fields[5].replacingOccurrences(of: ",", with: ".")
            guard let rssKB = Double(rssStr) else { continue }
            let cpuStr = fields[2].replacingOccurrences(of: ",", with: ".")
            guard let cpu = Double(cpuStr) else { continue }
            
            if command.contains("qemu") {
                let avdName = extractAVDName(from: command)
                result[avdName] = ResourceUsage(deviceID: avdName, memoryBytes: UInt64(rssKB * 1024), cpuPercent: cpu)
            } else if command.contains("Simulator") || command.contains("simctl") {
                for udid in iosDeviceIDs {
                    result[udid] = ResourceUsage(deviceID: udid, memoryBytes: UInt64(rssKB * 1024), cpuPercent: cpu)
                }
            }
        }
        return result
    }
    
    private func extractAVDName(from command: String) -> String {
        if let range = command.range(of: "-avd ") {
            let rest = command[range.upperBound...]
            return rest.split(separator: " ").first.map(String.init) ?? "unknown"
        }
        return "unknown"
    }
}
