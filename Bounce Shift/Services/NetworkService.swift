import Foundation
import UIKit

final class NetworkService {
    static let shared = NetworkService()
    
    private let baseEndpoint = "https://infoaitextapps.site/ios-bounceshift-reflexesball/server.php"
    
    private init() {}
    
    func fetchConfiguration() async throws -> ConfigurationResponse {
        let queryItems = buildQueryItems()
        
        var components = URLComponents(string: baseEndpoint)
        components?.queryItems = queryItems
        
        guard let requestPath = components?.url else {
            throw NetworkError.invalidPath
        }
        
        var request = URLRequest(url: requestPath)
        request.httpMethod = "GET"
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("no-cache", forHTTPHeaderField: "Pragma")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }
        
        guard let responseString = String(data: data, encoding: .utf8) else {
            throw NetworkError.decodingFailed
        }
        
        return parseResponse(responseString)
    }
    
    private func buildQueryItems() -> [URLQueryItem] {
        let osVersion = UIDevice.current.systemVersion
        let language = getSystemLanguage()
        let deviceModel = getDeviceModel()
        let country = getCountryCode()
        
        return [
            URLQueryItem(name: "p", value: "Bs2675kDjkb5Ga"),
            URLQueryItem(name: "os", value: osVersion),
            URLQueryItem(name: "lng", value: language),
            URLQueryItem(name: "devicemodel", value: deviceModel),
            URLQueryItem(name: "country", value: country)
        ]
    }
    
    private func getSystemLanguage() -> String {
        let preferredLanguage = Locale.preferredLanguages.first ?? "en"
        if let dashIndex = preferredLanguage.firstIndex(of: "-") {
            return String(preferredLanguage[..<dashIndex])
        }
        return preferredLanguage
    }
    
    private func getDeviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier.lowercased()
    }
    
    private func getCountryCode() -> String {
        return Locale.current.region?.identifier ?? "US"
    }
    
    private func parseResponse(_ response: String) -> ConfigurationResponse {
        let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let separatorIndex = trimmed.firstIndex(of: "#") {
            let token = String(trimmed[..<separatorIndex])
            let path = String(trimmed[trimmed.index(after: separatorIndex)...])
            return ConfigurationResponse(token: token, contentPath: path, showContent: true)
        }
        
        return ConfigurationResponse(token: nil, contentPath: nil, showContent: false)
    }
}

struct ConfigurationResponse {
    let token: String?
    let contentPath: String?
    let showContent: Bool
}

enum NetworkError: Error {
    case invalidPath
    case invalidResponse
    case decodingFailed
}
