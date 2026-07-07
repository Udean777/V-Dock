import Foundation

final class DiscoverDevicesUseCase: Sendable {
    private let repos: [DeviceRepositoryProtocol]

    init(repos: [DeviceRepositoryProtocol]) {
        self.repos = repos
    }

    func execute() async -> (devices: [Device], errors: [String]) {
        var allDevices: [Device] = []
        var allErrors: [String] = []
        for repo in repos {
            do {
                let result = try await repo.fetchAll()
                allDevices.append(contentsOf: result)
            } catch {
                allErrors.append("\(type(of: repo)): \(error)")
            }
        }
        return (allDevices, allErrors)
    }
}
