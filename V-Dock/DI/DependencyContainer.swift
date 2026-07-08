import Foundation

@MainActor
final class DependencyContainer {
    let appState: AppState
    
    init() {
        let shell = ShellExecutor()
        let simulatorRepo = SimulatorRepository(shell: shell)
        let androidRepo = AndroidEmulatorRepository(shell: shell)
        let discoverUseCase = DiscoverDevicesUseCase(repos: [simulatorRepo, androidRepo])
        let lifecycleUseCase = DeviceLifecycleUseCase(
            iosLifecycle: simulatorRepo,
            androidLifecycle: androidRepo
        )
        let resourceUseCase = ResourceMonitorUseCase(monitor: MacOSResourceMonitor(shell: shell))
        let mediaCaptureUseCase = MediaCaptureUseCase(
            iosCapture: simulatorRepo,
            androidCapture: androidRepo
        )
        let quickTogglesUseCase = QuickTogglesUseCase(
            iosToggles: simulatorRepo,
            androidToggles: androidRepo
        )
        let logStreamUseCase = LogStreamUseCase(
            iosStream: simulatorRepo,
            androidStream: androidRepo
        )
        
        appState = AppState(
            discoverUseCase: discoverUseCase,
            lifecycleUseCase: lifecycleUseCase,
            resourceUseCase: resourceUseCase,
            mediaCaptureUseCase: mediaCaptureUseCase,
            quickTogglesUseCase: quickTogglesUseCase,
            logStreamUseCase: logStreamUseCase
        )
    }
}
