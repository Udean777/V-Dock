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
    let pairingUseCase: WirelessPairingUseCase
    let pushFileUseCase: PushFileUseCase
    let updateChecker: UpdateCheckerViewModel
    
    init(
        discoverUseCase: DiscoverDevicesUseCase,
        lifecycleUseCase: DeviceLifecycleUseCase,
        resourceUseCase: ResourceMonitorUseCase,
        mediaCaptureUseCase: MediaCaptureUseCase,
        quickTogglesUseCase: QuickTogglesUseCase,
        logStreamUseCase: LogStreamUseCase,
        pairingUseCase: WirelessPairingUseCase,
        pushFileUseCase: PushFileUseCase,
        updateChecker: UpdateCheckerViewModel
    ) {
        self.discoverUseCase = discoverUseCase
        self.lifecycleUseCase = lifecycleUseCase
        self.resourceUseCase = resourceUseCase
        self.mediaCaptureUseCase = mediaCaptureUseCase
        self.quickTogglesUseCase = quickTogglesUseCase
        self.logStreamUseCase = logStreamUseCase
        pinnedIDs = Set(UserDefaults.standard.stringArray(forKey: "pinnedIDs") ?? [])
        androidSDKPath = UserDefaults.standard.string(forKey: "androidSDKPath") ?? ""
        isLaunchAtLoginEnabled = SMAppService.mainApp.status == .enabled
        self.pairingUseCase = pairingUseCase
        self.pushFileUseCase = pushFileUseCase
        self.updateChecker = updateChecker
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
        
        // Detect newly booted devices
        let newlyBooted = result.devices.filter { newDev in
            newDev.status == .booted && devices.contains(where: { oldDev in oldDev.id == newDev.id && oldDev.status != .booted })
        }
        
        for dev in newlyBooted {
            NotificationManager.shared.sendNotification(title: "Device Ready", body: "\(dev.name) has finished booting.")
        }
        
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
            
            if action == .wipeData {
                let message = device.platform == .ios ? "Factory reset complete." : "Data wiped successfully."
                NotificationManager.shared.sendNotification(title: "Wipe Complete", body: "\(device.name): \(message)")
            } else if action == .coldBoot {
                NotificationManager.shared.sendNotification(title: "Cold Boot Initiated", body: "\(device.name) is restarting from a clean state.")
            }
            
        } catch {
            actionError = "Failed to \(action): \(error.localizedDescription)"
            NotificationManager.shared.sendNotification(title: "Action Failed", body: actionError ?? "")
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
            NotificationManager.shared.sendNotification(title: "Screenshot Saved", body: "Saved to Desktop as \(filename)")
        } catch {
            actionError = "Failed to take screenshot: \(error.localizedDescription)"
            NotificationManager.shared.sendNotification(title: "Screenshot Failed", body: error.localizedDescription)
        }
    }
    
    func toggleRecording(for device: Device) async {
        if recordingDeviceID == device.id {
            // Stop recording
            recordingDeviceID = nil
            do {
                try await mediaCaptureUseCase.stopRecording(device: device)
                NSSound(named: "Glass")?.play()
                NotificationManager.shared.sendNotification(title: "Recording Saved", body: "Screen recording saved to Desktop.")
            } catch {
                actionError = "Failed to stop recording: \(error.localizedDescription)"
                NotificationManager.shared.sendNotification(title: "Recording Failed", body: error.localizedDescription)
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
                NotificationManager.shared.sendNotification(title: "Recording Failed", body: error.localizedDescription)
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
    
    func openPairing() {
        NotificationCenter.default.post(name: NSNotification.Name("OpenPairing"), object: nil)
    }

    func refreshPairingServices() async -> [DiscoveredService] {
        (try? await pairingUseCase.discoverServices()) ?? []
    }
}
