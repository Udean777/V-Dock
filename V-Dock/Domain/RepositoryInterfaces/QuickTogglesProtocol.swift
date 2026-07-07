import Foundation

protocol QuickTogglesProtocol: Sendable {
    func setDarkMode(device: Device, isDark: Bool) async throws
}
