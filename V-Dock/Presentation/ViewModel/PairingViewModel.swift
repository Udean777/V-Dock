import Foundation
import Observation
import AppKit
import CoreImage

enum PairingStep: Sendable, Equatable {
    case idle
    case qrDisplay
    case waitingForPhone
    case pairing
    case manualEntry
    case done(String)
    case error(String)
}

struct MDNSDevice: Sendable, Identifiable {
    let id: String
    let host: String
    let port: Int
    let serviceName: String
}

@MainActor
@Observable
final class PairingViewModel {
    let pairingUseCase: WirelessPairingUseCase

    var step: PairingStep = .idle
    var host = ""
    var port = ""
    var code = ""

    var qrServiceName = ""
    var qrPassword = ""
    var qrCodeImage: NSImage?
    var mdnspollTask: Task<Void, Never>?
    var statusMessage = ""

    init(pairingUseCase: WirelessPairingUseCase) {
        self.pairingUseCase = pairingUseCase
    }

    func showManualEntry() {
        reset()
        step = .manualEntry
    }

    func reset() {
        mdnspollTask?.cancel()
        mdnspollTask = nil
        step = .idle
        host = ""
        port = ""
        code = ""
        qrServiceName = ""
        qrPassword = ""
        qrCodeImage = nil
        statusMessage = ""
    }

    func close() {
        mdnspollTask?.cancel()
        mdnspollTask = nil
        NSApp.windows.first(where: { $0.title == "Pair Wireless Device" })?.close()
    }

    func generateQRCode() {
        qrServiceName = "v-dock-\(randomString(length: 8))"
        qrPassword = randomString(length: 12)

        let qrData = "WIFI:T:ADB;S:\(qrServiceName);P:\(qrPassword) ;;"
        qrCodeImage = generateQRImage(from: qrData)

        step = .qrDisplay
        statusMessage = "QR code siap. Buka Wireless debugging di HP > Pair with QR code, lalu scan kode ini."

        startMDNSPolling()
    }

    private func startMDNSPolling() {
        mdnspollTask?.cancel()
        mdnspollTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                step = .waitingForPhone
                statusMessage = "Menunggu HP scan QR code..."

                if let device = await detectPhone() {
                    host = device.host
                    port = String(device.port)
                    code = qrPassword
                    await performPair()
                    return
                }

                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }
    }

    private func detectPhone() async -> (host: String, port: Int, serviceName: String)? {
        guard let services = try? await pairingUseCase.discoverServices() else { return nil }
        return services
            .filter { $0.serviceName == qrServiceName }
            .first
            .map { (host: $0.host, port: $0.port, serviceName: $0.serviceName) }
    }

    func pairManual() async {
        guard !host.isEmpty, !port.isEmpty, !code.isEmpty else {
            step = .error("Host, port, dan kode pairing harus diisi.")
            return
        }
        await performPair()
    }

    private func performPair() async {
        step = .pairing
        statusMessage = "Pairing dengan \(host):\(port)..."
        do {
            try await pairingUseCase.pairAndConnect(
                host: host, port: Int(port) ?? 0, code: code
            )
            step = .done("\(host):\(port)")
            mdnspollTask?.cancel()
            NotificationManager.shared.sendNotification(title: "Wireless ADB Connected", body: "Successfully paired with \(host):\(port)")
        } catch {
            step = .error(error.localizedDescription)
            NotificationManager.shared.sendNotification(title: "Pairing Failed", body: error.localizedDescription)
        }
    }

    private func generateQRImage(from string: String) -> NSImage? {
        guard let data = string.data(using: .utf8),
              let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        guard let qrImage = filter.outputImage else { return nil }

        let scale: CGFloat = 10
        let scaled = qrImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let rep = NSCIImageRep(ciImage: scaled)
        let nsImage = NSImage(size: rep.size)
        nsImage.addRepresentation(rep)
        return nsImage
    }

    private func randomString(length: Int) -> String {
        let chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map { _ in chars.randomElement()! })
    }
}
