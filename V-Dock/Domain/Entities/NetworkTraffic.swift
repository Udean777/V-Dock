import Foundation

public struct NetworkTraffic: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let method: String
    public let url: String
    public let requestHeaders: [String: String]
    public let requestBody: Data?
    public var responseCode: Int?
    public var responseHeaders: [String: String]?
    public var responseBody: Data?
    public var timestamp: Date

    public init(id: UUID = UUID(), method: String, url: String, requestHeaders: [String: String] = [:], requestBody: Data? = nil, responseCode: Int? = nil, responseHeaders: [String: String]? = nil, responseBody: Data? = nil, timestamp: Date = Date()) {
        self.id = id
        self.method = method
        self.url = url
        self.requestHeaders = requestHeaders
        self.requestBody = requestBody
        self.responseCode = responseCode
        self.responseHeaders = responseHeaders
        self.responseBody = responseBody
        self.timestamp = timestamp
    }
}
