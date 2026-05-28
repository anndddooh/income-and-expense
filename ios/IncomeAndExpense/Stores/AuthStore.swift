import Foundation
import Observation

@Observable
@MainActor
final class AuthStore {
    static let shared = AuthStore()

    private(set) var isLoggedIn: Bool = KeychainStore.accessToken != nil

    private init() {}

    func login(username: String, password: String) async throws {
        let body = try JSONCoders.encoder.encode(
            LoginRequest(username: username, password: password)
        )
        let endpoint = APIEndpoint(
            path: "/auth/login/",
            method: .post,
            body: body,
            requiresAuth: false
        )
        let tokens: AuthTokens = try await APIClient.shared.request(endpoint)
        KeychainStore.accessToken = tokens.access
        KeychainStore.refreshToken = tokens.refresh
        isLoggedIn = true
    }

    func logout() {
        KeychainStore.clear()
        isLoggedIn = false
    }
}
