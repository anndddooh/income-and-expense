import Foundation

enum AppError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case httpError(statusCode: Int, body: Data)
    case decodingFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "URLの構築に失敗しました"
        case .invalidResponse: return "サーバーからの応答が不正です"
        case .unauthorized: return "認証が切れました。再ログインしてください"
        case .httpError(let status, let body):
            if let detail = Self.parseDRFError(from: body) {
                return detail
            }
            if !body.isEmpty, let text = String(data: body, encoding: .utf8) {
                return "通信エラー(HTTP \(status)): \(text.prefix(200))"
            }
            return "通信エラー(HTTP \(status))"
        case .decodingFailed: return "レスポンスの解析に失敗しました"
        }
    }

    /// DRFのValidationErrorレスポンスを読みやすい文字列に変換。
    /// - `{"field": ["msg"], ...}`(serializer validate_xxx)
    /// - `{"detail": "msg"}`(NotAuthenticated, NotFound等)
    /// - `["msg"]`(viewの @action 内で raise ValidationError("msg") した場合)
    private static func parseDRFError(from data: Data) -> String? {
        guard !data.isEmpty,
              let json = try? JSONSerialization.jsonObject(with: data) else {
            return nil
        }

        if let array = json as? [String], !array.isEmpty {
            return array.joined(separator: "\n")
        }

        guard let dict = json as? [String: Any] else { return nil }
        if let detail = dict["detail"] as? String {
            return detail
        }
        var messages: [String] = []
        for key in dict.keys.sorted() {
            switch dict[key] {
            case let array as [String]:
                messages.append(contentsOf: array)
            case let str as String:
                messages.append(str)
            default:
                continue
            }
        }
        return messages.isEmpty ? nil : messages.joined(separator: "\n")
    }
}

final class APIClient {
    static let shared = APIClient()

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        let (data, _) = try await sendWithRetry(endpoint)
        do {
            return try JSONCoders.decoder.decode(T.self, from: data)
        } catch {
            throw AppError.decodingFailed(underlying: error)
        }
    }

    func requestVoid(_ endpoint: APIEndpoint) async throws {
        _ = try await sendWithRetry(endpoint)
    }

    /// 401 を受けたらリフレッシュ&リトライを 1 回だけ行う送信。
    private func sendWithRetry(_ endpoint: APIEndpoint) async throws -> (Data, HTTPURLResponse) {
        let request = try makeURLRequest(endpoint)
        let (data, response) = try await session.data(for: request)
        let http = try ensureHTTPResponse(response)

        if http.statusCode == 401, endpoint.requiresAuth {
            do {
                _ = try await TokenRefresher.shared.refreshAccessToken()
            } catch {
                await AuthStore.shared.logout()
                throw AppError.unauthorized
            }
            let retryRequest = try makeURLRequest(endpoint)
            let (retryData, retryResponse) = try await session.data(for: retryRequest)
            let retryHttp = try ensureHTTPResponse(retryResponse)
            if retryHttp.statusCode == 401 {
                await AuthStore.shared.logout()
                throw AppError.unauthorized
            }
            try validate(http: retryHttp, data: retryData)
            return (retryData, retryHttp)
        }

        try validate(http: http, data: data)
        return (data, http)
    }

    private func makeURLRequest(_ endpoint: APIEndpoint) throws -> URLRequest {
        guard var components = URLComponents(
            url: AppConfig.baseURL,
            resolvingAgainstBaseURL: false
        ) else {
            throw AppError.invalidURL
        }
        components.path = components.path + endpoint.path
        components.queryItems = endpoint.queryItems

        guard let url = components.url else {
            throw AppError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = endpoint.body
        if endpoint.body != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if endpoint.requiresAuth, let token = KeychainStore.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    private func ensureHTTPResponse(_ response: URLResponse) throws -> HTTPURLResponse {
        guard let http = response as? HTTPURLResponse else {
            throw AppError.invalidResponse
        }
        return http
    }

    private func validate(http: HTTPURLResponse, data: Data) throws {
        guard (200..<300).contains(http.statusCode) else {
            throw AppError.httpError(statusCode: http.statusCode, body: data)
        }
    }
}
