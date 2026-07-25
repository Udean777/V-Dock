import SwiftUI

struct ResourceBarView: View {
    let usage: ResourceUsage

    private var memMB: Double { Double(usage.memoryBytes) / 1_048_576 }
    private var memFraction: Double { min(memMB / 4096, 1.0) }
    private var cpuFraction: Double { min(usage.cpuPercent / 100, 1.0) }

    var body: some View {
        VStack(spacing: 4) {
            MetricRow(icon: "memorychip", value: "\(Int(memMB)) MB", fraction: memFraction)
            MetricRow(icon: "cpu", value: "\(Int(usage.cpuPercent))%", fraction: cpuFraction)
        }
    }
}

private struct MetricRow: View {
    let icon: String
    let value: String
    let fraction: Double

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(.secondary)
            ProgressView(value: fraction)
                .tint(gradientColor)
                .frame(maxWidth: 120)
            Text(value)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(minWidth: 50, alignment: .trailing)
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
