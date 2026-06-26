import Foundation

enum AppConfig {
    static let baseURL: URL = {
        guard
            let scheme = Bundle.main.object(forInfoDictionaryKey: "API_SCHEME") as? String,
            !scheme.isEmpty,
            let host = Bundle.main.object(forInfoDictionaryKey: "API_HOST") as? String,
            !host.isEmpty,
            let url = URL(string: "\(scheme)://\(host)/api")
        else {
            fatalError("API_SCHEME / API_HOST が Info.plist (xcconfig) に未設定です")
        }
        return url
    }()
}
