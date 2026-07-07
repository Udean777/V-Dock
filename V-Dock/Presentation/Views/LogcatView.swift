import SwiftUI

struct LogEntry: Identifiable, Equatable {
    let id = UUID()
    let message: String
    
    var color: Color {
        let lower = message.lowercased()
        if lower.contains(" error") || lower.contains("fatal") || lower.contains("exception") || lower.hasPrefix("e/") {
            return .red
        } else if lower.contains(" warn") || lower.hasPrefix("w/") {
            return .orange
        } else if lower.contains(" debug") || lower.hasPrefix("d/") {
            return .cyan
        } else {
            return .primary
        }
    }
}

struct LogcatView: View {
    let device: Device
    @Environment(AppState.self) var state
    
    @State private var logs: [LogEntry] = []
    @State private var searchText = ""
    @State private var isAutoScrollEnabled = true
    @State private var logTask: Task<Void, Never>?
    
    var filteredLogs: [LogEntry] {
        if searchText.isEmpty {
            return logs
        } else {
            return logs.filter { $0.message.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Filter logs...", text: $searchText)
                    .textFieldStyle(.plain)
                
                Spacer()
                
                Toggle("Auto-scroll", isOn: $isAutoScrollEnabled)
                    .toggleStyle(.switch)
                    .padding(.trailing, 8)
                
                Button(role: .destructive) {
                    logs.removeAll()
                } label: {
                    Image(systemName: "trash")
                    Text("Clear")
                }
                .buttonStyle(.bordered)
            }
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Log Content
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(filteredLogs) { log in
                            Text(log.message)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(log.color)
                                .textSelection(.enabled)
                                .id(log.id)
                        }
                    }
                    .padding()
                }
                .background(Color(NSColor.textBackgroundColor))
                .onChange(of: filteredLogs.count) {
                    if isAutoScrollEnabled, let last = filteredLogs.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
        .onAppear {
            startStreaming()
        }
        .onDisappear {
            stopStreaming()
        }
    }
    
    private func startStreaming() {
        logs.removeAll()
        logTask = Task {
            let stream = state.logStreamUseCase.streamLogs(for: device)
            for await line in stream {
                if Task.isCancelled { break }
                let entry = LogEntry(message: line)
                logs.append(entry)
                
                // Limit logs to prevent memory overflow
                if logs.count > 3000 {
                    logs.removeFirst(500)
                }
            }
        }
    }
    
    private func stopStreaming() {
        logTask?.cancel()
        logTask = nil
    }
}
