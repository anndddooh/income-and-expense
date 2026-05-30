import Foundation

enum AppConfig {
    static let baseURL: URL = {
        #if DEBUG
        return URL(string: "http://localhost:8000/api")!
        #else
        return URL(string: "https://income-and-expense.167.172.65.18.nip.io/api")!
        #endif
    }()
}
