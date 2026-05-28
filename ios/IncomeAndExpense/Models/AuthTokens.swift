import Foundation

struct AuthTokens: Codable {
    let access: String
    let refresh: String
}

struct AccessTokenResponse: Codable {
    let access: String
}

struct LoginRequest: Codable {
    let username: String
    let password: String
}

struct RefreshRequest: Codable {
    let refresh: String
}
