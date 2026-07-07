import Foundation

enum ShellError: Error {
    case nonZeroExit(code: Int, stderr: String)
    case executableNotFound(String)
}

final class ShellExecutor: Sendable {
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
}
