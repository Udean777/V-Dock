import Foundation

@MainActor
final class DependencyContainer {
    let appState: AppState
    
    init() {
        let shell = ShellExecutor()
        let simulatorRepo = SimulatorRepository(shell: shell)
        let androidRepo = AndroidEmulatorRepository(shell: shell)
        let wirelessRepo = WirelessADBRepository(shell: shell)
        let discoverUseCase = DiscoverDevicesUseCase(repos: [simulatorRepo, androidRepo, wirelessRepo])
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
        let pairingUseCase = WirelessPairingUseCase(wirelessRepo: wirelessRepo)
        
        let androidPushFileRepo = AndroidPushFileRepository(executor: shell)
        let iosPushFileRepo = IOSSimulatorPushFileRepository(executor: shell)
        let pushFileUseCase = PushFileUseCase(androidRepo: androidPushFileRepo, iosRepo: iosPushFileRepo)

        let releaseChecker = ReleaseChecker()
        let updateChecker = UpdateCheckerViewModel(checker: releaseChecker)

        appState = AppState(
            discoverUseCase: discoverUseCase,
            lifecycleUseCase: lifecycleUseCase,
            resourceUseCase: resourceUseCase,
            mediaCaptureUseCase: mediaCaptureUseCase,
            quickTogglesUseCase: quickTogglesUseCase,
            logStreamUseCase: logStreamUseCase,
            pairingUseCase: pairingUseCase,
            pushFileUseCase: pushFileUseCase,
            updateChecker: updateChecker
        )
    }
}
