import SwiftUI

struct ResourceBarView: View {
    let usage: ResourceUsage
    
    private var memMB: Double {
        Double(usage.memoryBytes) / 1_048_576
    }
    
    private var fraction: Double {
        min(memMB / 4096, 1.0)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "memorychip")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                ProgressView(value: fraction)
                    .tint(gradientColor)
                    .frame(maxWidth: 120)
                Text("\(Int(memMB)) MB")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 50, alignment: .trailing)
            }
            HStack(spacing: 4) {
                Image(systemName: "cpu")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                ProgressView(value: min(usage.cpuPercent / 100, 1.0))
                    .tint(gradientColor)
                    .frame(maxWidth: 120)
                Text("\(Int(usage.cpuPercent))%")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 50, alignment: .trailing)
            }
        }
    }
    
    private var gradientColor: Color {
        switch fraction {
        case ..<0.5: .green
        case ..<0.8: .yellow
        default: .red
        }
    }
}
