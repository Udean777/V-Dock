import SwiftUI

struct QRCodeDisplayView: View {
    let image: NSImage?

    var body: some View {
        if let image {
            Image(nsImage: image)
                .interpolation(.none)
                .resizable()
                .aspectRatio(1, contentMode: .fit)
        } else {
            Rectangle()
                .fill(.secondary.opacity(0.1))
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    Image(systemName: "qrcode")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                }
        }
    }
}
