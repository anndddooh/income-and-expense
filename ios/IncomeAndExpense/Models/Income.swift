import Foundation

struct Income: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let payDate: Date
    let method: Int
    let methodName: String
    let account: EmbeddedAccount
    let amount: Int
    let formedAmount: String
    let state: InexState
    let stateLabel: String
    let memo: String?

    enum CodingKeys: String, CodingKey {
        case id, name, method, account, amount, state, memo
        case payDate = "pay_date"
        case methodName = "method_name"
        case formedAmount = "formed_amount"
        case stateLabel = "state_label"
    }
}

struct IncomeInput: Codable {
    let name: String
    let payDate: Date
    let method: Int
    let amount: Int
    let state: InexState
    let memo: String?

    enum CodingKeys: String, CodingKey {
        case name, method, amount, state, memo
        case payDate = "pay_date"
    }
}
