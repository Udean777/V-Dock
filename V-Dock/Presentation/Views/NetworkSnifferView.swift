import SwiftUI
import AppKit

struct NetworkSnifferView: View {
    let device: Device
    
    // In a real app we'd use a ViewModel. For MVP, we'll hold state here.
    @State private var traffic: [NetworkTraffic] = []
    @State private var isSniffing = false
    @State private var selectedTraffic: NetworkTraffic?
    
    var body: some View {
        NavigationSplitView {
            List(traffic, selection: $selectedTraffic) { item in
                HStack {
                    Text(item.method)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(colorForMethod(item.method))
                        .frame(width: 45, alignment: .leading)
                    
                    Text(item.url)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .font(.system(size: 13))
                }
                .tag(item)
            }
            .navigationTitle("Requests")
            .frame(minWidth: 250)
            
        } detail: {
            if let traffic = selectedTraffic {
                VSplitView {
                    VStack(alignment: .leading) {
                        Text("Request")
                            .font(.headline)
                            .padding()
                        
                        Text("Method: \(traffic.method)")
                            .padding(.horizontal)
                        Text("URL: \(traffic.url)")
                            .padding(.horizontal)
                        
                        Divider()
                        
                        Text("Headers: \(traffic.requestHeaders.description)")
                            .padding(.horizontal)
                            .font(.system(.body, design: .monospaced))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    
                    VStack(alignment: .leading) {
                        Text("Response")
                            .font(.headline)
                            .padding()
                        
                        Text("Coming soon...")
                            .padding(.horizontal)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            } else {
                Text("Select a request to view details")
                    .foregroundColor(.secondary)
            }
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    traffic.removeAll()
                }) {
                    Image(systemName: "trash")
                }
                .help("Clear Traffic")
            }
        }
        .onAppear {
            startSniffing()
        }
        .onDisappear {
            stopSniffing()
        }
    }
    
    private func colorForMethod(_ method: String) -> Color {
        switch method {
        case "GET": return .green
        case "POST": return .orange
        case "PUT": return .blue
        case "DELETE": return .red
        case "CONNECT": return .purple
        default: return .primary
        }
    }
    
    private func startSniffing() {
        // Implementation for injecting UseCase and starting proxy.
        // For this step, we just populate mock data or leave it empty as the use case injection comes from DependencyContainer.
        print("Starting network sniffer for \(device.name)")
    }
    
    private func stopSniffing() {
        print("Stopping network sniffer for \(device.name)")
    }
}
