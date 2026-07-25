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
        let networkProxyUseCase = NetworkProxyUseCase(
            androidRepo: androidRepo,
            iosRepo: simulatorRepo
        )
        let networkSnifferUseCase = NetworkSnifferUseCase(
            proxyServer: LocalProxyServer()
        )
        let androidScreenMirror = AndroidScreenMirror(shell: shell)
        let screenMirrorUseCase = ScreenMirrorUseCase(androidMirror: androidScreenMirror)
        
        let pairingUseCase = WirelessPairingUseCase(wirelessRepo: wirelessRepo)

        appState = AppState(
            discoverUseCase: discoverUseCase,
            lifecycleUseCase: lifecycleUseCase,
            resourceUseCase: resourceUseCase,
            mediaCaptureUseCase: mediaCaptureUseCase,
            quickTogglesUseCase: quickTogglesUseCase,
            logStreamUseCase: logStreamUseCase,
            networkProxyUseCase: networkProxyUseCase,
            networkSnifferUseCase: networkSnifferUseCase,
            mirrorUseCase: screenMirrorUseCase,
            pairingUseCase: pairingUseCase
        )
    }
}
