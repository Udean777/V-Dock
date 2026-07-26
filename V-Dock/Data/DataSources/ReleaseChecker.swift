//
//  ReleaseChecker.swift
//  V-Dock
//
//  Created by Sajudin on 26/07/26.
//

import Foundation

struct ReleaseInfo: Sendable, Equatable {
    let version: String
    let downloadURL: URL
}

final class ReleaseChecker: Sendable {
    private let repo: String
    
    init(repo: String = "Udean777/V-Dock") {
        self.repo = repo
    }
    
    func fetchLatestRelease() async throws -> ReleaseInfo {
        let url = URL(string: "https://api.github.com/repos/\(repo)/releases/latest")!
        
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("V-Dock/1.0", forHTTPHeaderField: "User-Agent")
        
        let (data, response): (Data, URLResponse)
        
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw ReleaseCheckError.networkError(error)
        }
        
        guard let http = response as? HTTPURLResponse, 200...299 ~= http.statusCode else {
            throw ReleaseCheckError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        let release = try decoder.decode(GitHubRelease.self, from: data)
        
        let version = release.tagName.hasPrefix("v") ? String(release.tagName.dropFirst()) : release.tagName
        
        guard let dmg = release.assets.first(where: { $0.name.hasSuffix(".dmg") }) else {
            throw ReleaseCheckError.noDMGAsset
        }
        
        return ReleaseInfo(version: version, downloadURL: dmg.browserDownloadUrl)
    }
}

enum ReleaseCheckError: Error, LocalizedError, Equatable{
    case networkError(Error)
    case invalidResponse
    case noDMGAsset
    
    var errorDescription: String? {
        switch self {
        case .networkError(let e): return "Network error: \(e.localizedDescription)"
        case .invalidResponse: return "Invalid response from GitHub"
        case .noDMGAsset: return "No DMG found in latest release"
        }
    }
    
    static func == (lhs: ReleaseCheckError, rhs: ReleaseCheckError) -> Bool {
        switch (lhs, rhs) {
        case (.networkError, .networkError), (.invalidResponse, .invalidResponse), (.noDMGAsset, .noDMGAsset):
            return true
        default:
            return false
        }
    }
}

private struct GitHubRelease: Decodable {
    let tagName: String
    let assets: [GitHubAsset]
}

private struct GitHubAsset: Decodable {
    let name: String
    let browserDownloadUrl: URL
}
