import Foundation
import KeychainAccess

enum KeychainStore {
    private static let keychain = Keychain(service: "com.ando.IncomeAndExpense")
    private static let accessKey = "access_token"
    private static let refreshKey = "refresh_token"

    static var accessToken: String? {
        get { try? keychain.get(accessKey) }
        set { setOrRemove(accessKey, value: newValue) }
    }

    static var refreshToken: String? {
        get { try? keychain.get(refreshKey) }
        set { setOrRemove(refreshKey, value: newValue) }
    }

    static func clear() {
        try? keychain.removeAll()
    }

    private static func setOrRemove(_ key: String, value: String?) {
        if let value {
            try? keychain.set(value, key: key)
        } else {
            try? keychain.remove(key)
        }
    }
}
