//
//  WirelessADBRepository.swift
//  V-Dock
//
//  Created by Sajudin on 25/07/26.
//

import Foundation

enum WirelessADBError: LocalizedError {
    case adbNotFound
    case pairingFailed(String)
    case connectionFailed(String)

    var errorDescription: String? {
        switch self {
        case .adbNotFound: "ADB not found. Install ADB or set Android SDK path."
        case .pairingFailed(let msg): "Pairing failed: \(msg)"
        case .connectionFailed(let msg): "Connection failed: \(msg)"
        }
    }
}

final class WirelessADBRepository: DeviceRepositoryProtocol, @unchecked Sendable {
    private let shell: ShellExecutor
    
    init(shell: ShellExecutor) {
        self.shell = shell
    }
    
    func fetchAll() async throws -> [Device] {
        guard let adb = resolveADBPath() else {return []}
        
        let output = try await shell.run(adb, args: ["devices", "-l"])
        
        return parseADBDevices(output)
    }
    
    private func parseADBDevices(_ output: String) -> [Device] {
        let lines = output.split(separator: "\n").dropFirst()
        
        return lines.compactMap { line -> Device? in
            let t = line.trimmingCharacters(in: .whitespaces)
            guard !t.isEmpty else { return nil }
            
            let parts = t.split(separator: " ", maxSplits: 1)
            guard parts.count >= 2, parts[1].hasPrefix("device") else { return nil }
            
            let serial = String(parts[0])
            guard !serial.contains("emulator-") else { return nil }
            
            let isWireless = serial.contains(":")
            
            return Device(
                id: serial, name: serial,
                platform: .android, status: .booted,
                connectionType: isWireless ? .wireless : .local
            )
        }
    }
    
    func connect(host: String, port: Int) async throws {
        guard let adb = resolveADBPath() else { return }
        _ = try await shell.run(adb, args: ["connect", "\(host):\(port)"])
    }
    
    func pair(host: String, port: Int, code: String) async throws {
        guard let adb = resolveADBPath() else { throw WirelessADBError.adbNotFound }
        let result = try await shell.run(adb, args: ["pair", "\(host):\(port)", code])
        guard !result.contains("failed") else {
            throw WirelessADBError.pairingFailed(result)
        }
    }

    func disconnect(host: String, port: Int) async throws {
        guard let adb = resolveADBPath() else { return }
        _ = try await shell.run(adb, args: ["disconnect", "\(host):\(port)"])
    }

    func discoverMDNS() async throws -> [(serviceName: String, host: String, port: Int)] {
        guard let adb = resolveADBPath() else { throw WirelessADBError.adbNotFound }
        let output = try await shell.run(adb, args: ["mdns", "services"])
        return parseMDNSServices(output)
    }

    private func parseMDNSServices(_ output: String) -> [(serviceName: String, host: String, port: Int)] {
        output.split(separator: "\n").compactMap { line in
            let t = line.trimmingCharacters(in: .whitespaces)
            guard !t.isEmpty, !t.hasPrefix("List of") else { return nil }
            let parts = t.split(separator: " ", omittingEmptySubsequences: true)
            guard parts.count >= 5 else { return nil }
            let serviceName = String(parts[2])
            let host = String(parts[3])
            let port = Int(parts[4]) ?? 0
            return port > 0 ? (serviceName, host, port) : nil
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
