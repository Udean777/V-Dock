import Foundation
import Network

public final class LocalProxyServer: NetworkSnifferProtocol, @unchecked Sendable {
    private var listener: NWListener?
    private var trafficContinuation: AsyncStream<NetworkTraffic>.Continuation?
    private let queue = DispatchQueue(label: "com.vdock.proxy", qos: .userInteractive)
    
    public init() {}
    
    public func startProxy(port: UInt16) async throws -> AsyncStream<NetworkTraffic> {
        let stream = AsyncStream<NetworkTraffic> { continuation in
            self.trafficContinuation = continuation
            do {
                let parameters = NWParameters.tcp
                let nwPort = NWEndpoint.Port(rawValue: port) ?? NWEndpoint.Port(integerLiteral: 8080)
                self.listener = try NWListener(using: parameters, on: nwPort)
                
                self.listener?.newConnectionHandler = { [weak self] connection in
                    self?.handleNewConnection(connection)
                }
                
                self.listener?.start(queue: self.queue)
                print("LocalProxyServer started on port \(port)")
            } catch {
                print("Failed to start proxy: \(error)")
                continuation.finish()
            }
        }
        return stream
    }
    
    public func stopProxy() async {
        listener?.cancel()
        listener = nil
        trafficContinuation?.finish()
        trafficContinuation = nil
    }
    
    private nonisolated func handleNewConnection(_ connection: NWConnection) {
        connection.start(queue: queue)
        receiveData(on: connection)
    }
    
    private nonisolated func receiveData(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 8192) { [weak self] data, context, isComplete, error in
            guard let self = self, let data = data, !data.isEmpty else {
                connection.cancel()
                return
            }
            
            // Simple parsing for MVP
            if let requestString = String(data: data, encoding: .utf8) {
                let lines = requestString.components(separatedBy: "\r\n")
                if let firstLine = lines.first {
                    let parts = firstLine.split(separator: " ")
                    if parts.count >= 2 {
                        let method = String(parts[0])
                        let url = String(parts[1])
                        
                        let traffic = NetworkTraffic(
                            method: method,
                            url: url,
                            requestHeaders: [:],
                            requestBody: data,
                            responseCode: nil,
                            responseHeaders: nil,
                            responseBody: nil,
                            timestamp: Date()
                        )
                        
                        self.trafficContinuation?.yield(traffic)
                        
                        // If it's a CONNECT request for HTTPS, we just mock a 200 OK to establish tunnel.
                        // Note: For a real proxy, we'd need to bridge to the remote server.
                        if method == "CONNECT" {
                            let response = "HTTP/1.1 200 Connection Established\r\n\r\n"
                            let responseData = response.data(using: .utf8)!
                            connection.send(content: responseData, completion: .contentProcessed({ _ in
                                // In a real proxy, we would now pipe data to the destination.
                                // For MVP we'll just close it or let it hang.
                                connection.cancel()
                            }))
                        } else {
                            // Mock a simple response for HTTP
                            let response = "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\nV-Dock Intercepted"
                            connection.send(content: response.data(using: .utf8)!, completion: .contentProcessed({ _ in
                                connection.cancel()
                            }))
                        }
                    } else {
                        connection.cancel()
                    }
                } else {
                    connection.cancel()
                }
            } else {
                connection.cancel()
            }
        }
    }
}
