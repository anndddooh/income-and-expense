import Foundation

/// `/auth/refresh/` を**最大1並行**で実行するためのアクター。
/// 401 を受けたリクエストが多数同時に走っても refresh 呼び出しは 1 つに集約される。
actor TokenRefresher {
    static let shared = TokenRefresher()

    private var inFlightTask: Task<String, Error>?

    func refreshAccessToken() async throws -> String {
        if let task = inFlightTask {
            return try await task.value
        }
        let task = Task<String, Error> {
            try await Self.performRefresh()
        }
        inFlightTask = task
        do {
            let result = try await task.value
            inFlightTask = nil
            return result
        } catch {
            inFlightTask = nil
            throw error
        }
    }

    private static func performRefresh() async throws -> String {
        guard let refreshToken = KeychainStore.refreshToken else {
            throw AppError.unauthorized
        }
        let body = try JSONCoders.encoder.encode(RefreshRequest(refresh: refreshToken))

        guard var components = URLComponents(
            url: AppConfig.baseURL,
            resolvingAgainstBaseURL: false
        ) else {
            throw AppError.invalidURL
        }
        components.path = components.path + "/auth/refresh/"
        guard let url = components.url else {
            throw AppError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            throw AppError.unauthorized
        }
        let decoded = try JSONCoders.decoder.decode(AccessTokenResponse.self, from: data)
        KeychainStore.accessToken = decoded.access
        return decoded.access
    }
}
