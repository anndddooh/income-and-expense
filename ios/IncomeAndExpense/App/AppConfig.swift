import Foundation

enum AppConfig {
    static let baseURL: URL = {
        #if DEBUG
        return URL(string: "http://localhost:8000/api")!
        #else
        return URL(string: "https://ha-apps.herokuapp.com/api")!
        #endif
    }()
}
