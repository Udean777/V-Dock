import Foundation
import Observation
import AppKit

@MainActor
@Observable
final class PushFileViewModel {
    var isTransferring = false
    var error: String?
    
    private let useCase: PushFileUseCase
    
    init(useCase: PushFileUseCase) {
        self.useCase = useCase
    }
    
    func pickFileAndPush(to device: Device) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.title = "Select Files to Push to \(device.name)"
        
        NSApp.activate(ignoringOtherApps: true)
        
        if panel.runModal() == .OK {
            let urls = panel.urls
            guard !urls.isEmpty else { return }
            Task {
                await push(files: urls, to: device)
            }
        }
    }
    
    func push(files urls: [URL], to device: Device, bundleId: String? = nil) async {
        isTransferring = true
        error = nil
        
        var failedFiles: [(String, String)] = []
        
        for url in urls {
            do {
                try await useCase.execute(device: device, filePath: url, bundleId: bundleId)
            } catch {
                failedFiles.append((url.lastPathComponent, error.localizedDescription))
            }
        }
        
        isTransferring = false
        
        if failedFiles.isEmpty {
            NSSound(named: "Glass")?.play()
        } else {
            NSSound(named: "Basso")?.play()
            let errorMessage = failedFiles.map { "\($0.0): \($0.1)" }.joined(separator: "\n")
            self.error = "Some files failed to transfer."
            showErrorAlert(message: errorMessage)
        }
    }
    
    @MainActor
    private func showErrorAlert(message: String) {
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = "File Transfer Failed"
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }
}
