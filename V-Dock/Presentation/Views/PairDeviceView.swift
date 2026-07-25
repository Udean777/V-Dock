import SwiftUI

struct PairDeviceView: View {
    @State private var vm: PairingViewModel

    init(pairingUseCase: WirelessPairingUseCase) {
        _vm = State(initialValue: PairingViewModel(pairingUseCase: pairingUseCase))
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Divider()
            footer
        }
        .frame(width: 420, height: 520)
        .background(.regularMaterial)
    }

    private var header: some View {
        HStack {
            if vm.step != .idle {
                Button { vm.reset() } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
                .buttonStyle(.link)
            }
            Text("Connect Wireless Device")
                .font(.headline)
            Spacer()
            if vm.step == .idle {
                Button("Close") { vm.close() }
                    .buttonStyle(.link)
            }
        }
        .padding()
    }

    @ViewBuilder
    private var content: some View {
        switch vm.step {
        case .idle:
            idleView
        case .qrDisplay, .waitingForPhone, .pairing:
            qrDisplayView
        case .manualEntry:
            manualEntryView
        case .done(let addr):
            doneView(addr: addr)
        case .error(let msg):
            errorView(msg: msg)
        }
    }

    private var idleView: some View {
        VStack(spacing: 20) {
            Image(systemName: "rectangle.and.hand.point.up.left.filled")
                .font(.system(size: 48))
                .foregroundStyle(.blue)

            Text("Hubungkan HP Android secara wireless. Pilih salah satu metode:")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)

            Button {
                vm.generateQRCode()
            } label: {
                Label("Tampilkan QR Code", systemImage: "qrcode")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)

            Button {
                vm.showManualEntry()
            } label: {
                Label("Masukkan Manual", systemImage: "keyboard")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.bordered)
        }
        .padding(32)
    }

    private var qrDisplayView: some View {
        VStack(spacing: 16) {
            QRCodeDisplayView(image: vm.qrCodeImage)
                .frame(width: 240, height: 240)
                .padding(.top, 16)

            VStack(spacing: 4) {
                Text(vm.statusMessage)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                if vm.step == .waitingForPhone || vm.step == .pairing {
                    ProgressView()
                        .controlSize(.small)
                }

                Text("Service: \(vm.qrServiceName)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 24)

            Button("Batal", role: .cancel) { vm.reset() }
                .buttonStyle(.link)
                .padding(.bottom, 8)
        }
    }

    private var manualEntryView: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Buka HP > Developer options > Wireless debugging > Pair with pairing code.\nMasukkan IP:Port dan kode yang tampil di HP.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                Group {
                    TextField("IP Address (contoh: 192.168.1.10)", text: $vm.host)
                    TextField("Port (contoh: 38527)", text: $vm.port)
                    TextField("Kode Pairing (6 digit)", text: $vm.code)
                }
                .textFieldStyle(.roundedBorder)
                .font(.body)

                Button("Pair & Connect") {
                    Task { await vm.pairManual() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(vm.host.isEmpty || vm.port.isEmpty || vm.code.isEmpty)
            }
            .padding(24)
        }
    }

    private func doneView(addr: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)
            Text("Berhasil terhubung ke \(addr)")
                .font(.headline)
            Button("Selesai") { vm.reset() }
                .buttonStyle(.borderedProminent)
        }
        .padding(32)
    }

    private func errorView(msg: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.red)
            Text(msg)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            HStack {
                Button("Coba Lagi") { vm.reset() }
                    .buttonStyle(.borderedProminent)
                Button("Back") { vm.reset() }
                    .buttonStyle(.bordered)
            }
        }
        .padding(32)
    }

    private var footer: some View {
        HStack {
            Text("Pastikan HP dan Mac terhubung ke jaringan WiFi yang sama")
                .font(.caption2)
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
