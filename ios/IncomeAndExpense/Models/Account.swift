import Foundation

struct Account: Codable, Identifiable, Hashable {
    let id: Int
    let bank: Int
    let user: Int
    let bankName: String
    let userName: String
    let balance: Int
    let formedBalance: String

    enum CodingKeys: String, CodingKey {
        case id, bank, user, balance
        case bankName = "bank_name"
        case userName = "user_name"
        case formedBalance = "formed_balance"
    }
}
