import Foundation

final class QuickTogglesUseCase: Sendable {
    private let iosToggles: QuickTogglesProtocol
    private let androidToggles: QuickTogglesProtocol
    
    init(iosToggles: QuickTogglesProtocol, androidToggles: QuickTogglesProtocol) {
        self.iosToggles = iosToggles
        self.androidToggles = androidToggles
    }
    
    private func handler(for device: Device) -> QuickTogglesProtocol {
        switch device.platform {
        case .ios: iosToggles
        case .android: androidToggles
        }
    }
    
    func setDarkMode(device: Device, isDark: Bool) async throws {
        try await handler(for: device).setDarkMode(device: device, isDark: isDark)
    }
}
