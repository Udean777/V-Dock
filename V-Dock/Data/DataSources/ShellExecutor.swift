import Foundation

enum ShellError: Error {
    case nonZeroExit(code: Int, stderr: String)
    case executableNotFound(String)
}

final class ShellExecutor: Sendable {
    private let tracker = ProcessTracker()
    
    actor ProcessTracker {
        private var runningProcesses: [String: Process] = [:]
        
        func store(_ process: Process, id: String) {
            runningProcesses[id] = process
        }
        
        func remove(id: String) {
            runningProcesses.removeValue(forKey: id)
        }
        
        func interrupt(id: String) {
            runningProcesses[id]?.interrupt()
            runningProcesses.removeValue(forKey: id)
        }
    }
    
    func run(_ executable: String, args: [String]) async throws -> String {
        return try await Task.detached {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: executable)
            process.arguments = args

            let outputPipe = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = outputPipe
            process.standardError = errorPipe

            do {
                try process.run()
            } catch {
                throw ShellError.executableNotFound(executable)
            }
            
            var outputData = Data()
            var errorData = Data()
            
            do {
                if let out = try outputPipe.fileHandleForReading.readToEnd() {
                    outputData = out
                }
                if let err = try errorPipe.fileHandleForReading.readToEnd() {
                    errorData = err
                }
            } catch {
                // handle read errors if any
            }
            
            process.waitUntilExit()

            let output = String(data: outputData, encoding: .utf8) ?? ""
            let errorOutput = String(data: errorData, encoding: .utf8) ?? ""

            if process.terminationStatus == 0 {
                return output
            } else {
                throw ShellError.nonZeroExit(code: Int(process.terminationStatus), stderr: errorOutput)
            }
        }.value
    }

    func runDetached(_ executable: String, args: [String]) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = args
        try process.run()
    }
    
    func spawn(id: String, executable: String, args: [String]) async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = args
        try process.run()
        await tracker.store(process, id: id)
    }
    
    func terminate(id: String) async {
        await tracker.interrupt(id: id)
    }
    
    func stream(id: String, executable: String, args: [String]) -> AsyncStream<String> {
        AsyncStream { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: executable)
            process.arguments = args
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            
            let fileHandle = pipe.fileHandleForReading
            
            fileHandle.readabilityHandler = { fh in
                let data = fh.availableData
                if data.isEmpty {
                    fh.readabilityHandler = nil
                    continuation.finish()
                    return
                }
                if let str = String(data: data, encoding: .utf8) {
                    let lines = str.components(separatedBy: .newlines)
                    for line in lines where !line.isEmpty {
                        continuation.yield(line)
                    }
                }
            }
            
            continuation.onTermination = { @Sendable _ in
                fileHandle.readabilityHandler = nil
                process.terminate()
                Task {
                    await self.tracker.remove(id: id)
                }
            }
            
            do {
                try process.run()
                Task {
                    await self.tracker.store(process, id: id)
                }
            } catch {
                continuation.finish()
            }
        }
    }
}
