import Foundation

struct Method: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let displayName: String

    enum CodingKeys: String, CodingKey {
        case id, name
        case displayName = "display_name"
    }
}

/// Income / Expense / Loan / DefaultIncome 等のレスポンスに埋め込まれる口座サマリ。
struct EmbeddedAccount: Codable, Hashable {
    let id: Int
    let user: String
    let bank: String
}
