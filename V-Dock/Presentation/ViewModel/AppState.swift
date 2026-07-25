import Foundation
import Observation
import ServiceManagement
import AppKit

@MainActor
@Observable
final class AppState {
    var devices: [Device] = []
    var pinnedIDs: Set<String> = []
    var resourceUsage: [String: ResourceUsage] = [:]
    var isRefreshing = false
    var isProcessingAction = false
    var refreshError: String?
    var actionError: String?
    var recordingDeviceID: String?
    var androidSDKPath: String {
        didSet {
            UserDefaults.standard.set(androidSDKPath, forKey: "androidSDKPath")
        }
    }
    var isLaunchAtLoginEnabled: Bool {
        didSet {
            try? isLaunchAtLoginEnabled
            ? SMAppService.mainApp.register()
            : SMAppService.mainApp.unregister()
        }
    }
    
    private let discoverUseCase: DiscoverDevicesUseCase
    private let lifecycleUseCase: DeviceLifecycleUseCase
    private let resourceUseCase: ResourceMonitorUseCase
    private let mediaCaptureUseCase: MediaCaptureUseCase
    private let quickTogglesUseCase: QuickTogglesUseCase
    let logStreamUseCase: LogStreamUseCase
    let networkProxyUseCase: NetworkProxyUseCase
    let networkSnifferUseCase: NetworkSnifferUseCase
    let mirrorUseCase: ScreenMirrorUseCase
    let pairingUseCase: WirelessPairingUseCase
    var mirroringDeviceID: String?
    
    init(
        discoverUseCase: DiscoverDevicesUseCase,
        lifecycleUseCase: DeviceLifecycleUseCase,
        resourceUseCase: ResourceMonitorUseCase,
        mediaCaptureUseCase: MediaCaptureUseCase,
        quickTogglesUseCase: QuickTogglesUseCase,
        logStreamUseCase: LogStreamUseCase,
        networkProxyUseCase: NetworkProxyUseCase,
        networkSnifferUseCase: NetworkSnifferUseCase,
        mirrorUseCase: ScreenMirrorUseCase,
        pairingUseCase: WirelessPairingUseCase
    ) {
        self.discoverUseCase = discoverUseCase
        self.lifecycleUseCase = lifecycleUseCase
        self.resourceUseCase = resourceUseCase
        self.mediaCaptureUseCase = mediaCaptureUseCase
        self.quickTogglesUseCase = quickTogglesUseCase
        self.logStreamUseCase = logStreamUseCase
        self.networkProxyUseCase = networkProxyUseCase
        self.networkSnifferUseCase = networkSnifferUseCase
        pinnedIDs = Set(UserDefaults.standard.stringArray(forKey: "pinnedIDs") ?? [])
        androidSDKPath = UserDefaults.standard.string(forKey: "androidSDKPath") ?? ""
        isLaunchAtLoginEnabled = SMAppService.mainApp.status == .enabled
        self.mirrorUseCase = mirrorUseCase
        self.pairingUseCase = pairingUseCase
    }
    
    var hasAndroidSDK: Bool {
        let candidates = [
            UserDefaults.standard.string(forKey: "androidSDKPath"),
            ProcessInfo.processInfo.environment["ANDROID_HOME"],
            ProcessInfo.processInfo.environment["ANDROID_SDK_ROOT"],
            "\(NSHomeDirectory())/Library/Android/sdk",
        ]
        return candidates.compactMap({ $0 }).contains { FileManager.default.fileExists(atPath: $0) }
    }
    
    func refresh() async {
        isRefreshing = true
        refreshError = nil
        let result = await discoverUseCase.execute()
        devices = result.devices
        if !result.errors.isEmpty {
            refreshError = result.errors.joined(separator: "\n")
        }
        isRefreshing = false
    }
    
    func perform(_ action: DeviceAction, on device: Device) async {
        isProcessingAction = true
        actionError = nil
        defer { isProcessingAction = false }
        
        do {
            try await lifecycleUseCase.execute(action, on: device)
        } catch {
            actionError = "Failed to \(action): \(error.localizedDescription)"
        }
        await refresh()
    }
    
    func togglePin(for device: Device) {
        if pinnedIDs.contains(device.id) {
            pinnedIDs.remove(device.id)
        } else {
            pinnedIDs.insert(device.id)
        }
        UserDefaults.standard.set(Array(pinnedIDs), forKey: "pinnedIDs")
    }
    
    func refreshResources() async {
        let booted = devices.filter { $0.status == .booted }
        resourceUsage = (try? await resourceUseCase.execute(bootedDevices: booted)) ?? [:]
    }
    
    var pinnedDevices: [Device] {
        devices.filter { pinnedIDs.contains($0.id) }
    }
    
    private func getDesktopURL(filename: String) -> URL {
        let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        return desktop.appendingPathComponent(filename)
    }
    
    private var timestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter.string(from: Date())
    }
    
    func takeScreenshot(for device: Device) async {
        isProcessingAction = true
        actionError = nil
        defer { isProcessingAction = false }
        
        let filename = "V-Dock_\(device.name.replacingOccurrences(of: " ", with: ""))_\(timestamp).png"
        let dest = getDesktopURL(filename: filename)
        
        do {
            try await mediaCaptureUseCase.takeScreenshot(device: device, destination: dest)
            NSSound(named: "Purr")?.play() // Feedback suara macOS bawaan
        } catch {
            actionError = "Failed to take screenshot: \(error.localizedDescription)"
        }
    }
    
    func toggleRecording(for device: Device) async {
        if recordingDeviceID == device.id {
            // Stop recording
            recordingDeviceID = nil
            do {
                try await mediaCaptureUseCase.stopRecording(device: device)
                NSSound(named: "Glass")?.play()
            } catch {
                actionError = "Failed to stop recording: \(error.localizedDescription)"
            }
        } else {
            // Ensure any existing recording is stopped first (only 1 at a time)
            if let existingID = recordingDeviceID, let existingDevice = devices.first(where: { $0.id == existingID }) {
                try? await mediaCaptureUseCase.stopRecording(device: existingDevice)
            }
            
            // Start recording
            let filename = "V-Dock_\(device.name.replacingOccurrences(of: " ", with: ""))_\(timestamp).mp4"
            let dest = getDesktopURL(filename: filename)
            
            do {
                try await mediaCaptureUseCase.startRecording(device: device, destination: dest)
                recordingDeviceID = device.id
                NSSound(named: "Tink")?.play()
            } catch {
                actionError = "Failed to start recording: \(error.localizedDescription)"
            }
        }
    }
    
    func setDarkMode(for device: Device, isDark: Bool) async {
        isProcessingAction = true
        actionError = nil
        defer { isProcessingAction = false }
        
        do {
            try await quickTogglesUseCase.setDarkMode(device: device, isDark: isDark)
            NSSound(named: "Pop")?.play()
        } catch {
            actionError = "Failed to toggle appearance: \(error.localizedDescription)"
        }
    }
    
    func openLogcat(for device: Device) {
        NotificationCenter.default.post(name: NSNotification.Name("OpenLogcat"), object: device)
    }
    
    func openMirror(for device: Device) {
        NotificationCenter.default.post(name: NSNotification.Name("OpenScreenMirror"), object: device)
    }
    
    func startMirrorStream(for device: Device) -> AsyncStream<CGImage> {
        mirroringDeviceID = device.id
        return mirrorUseCase.startMirror(device: device)
    }
    
    func stopMirror(for device: Device) {
        mirrorUseCase.stopMirror(device: device)
        mirroringDeviceID = nil
    }
    
    func sendTouch(device: Device, x: Int, y: Int, action: TouchAction) {
        mirrorUseCase.sendTouch(device: device, x: x, y: y, action: action)
    }
    
    func sendSwipe(device: Device, x1: Int, y1: Int, x2: Int, y2: Int, durationMs: Int) {
        mirrorUseCase.sendSwipe(device: device, x1: x1, y1: y1, x2: x2, y2: y2, durationMs: durationMs)
    }
    
    func sendKey(device: Device, key: String) {
        mirrorUseCase.sendKey(device: device, key: key)
    }
    
    func openNetworkSniffer(for device: Device) {
        NotificationCenter.default.post(name: NSNotification.Name("OpenNetworkSniffer"), object: device)
    }

    func openPairing() {
        NotificationCenter.default.post(name: NSNotification.Name("OpenPairing"), object: nil)
    }

    func refreshPairingServices() async -> [DiscoveredService] {
        (try? await pairingUseCase.discoverServices()) ?? []
    }
}
