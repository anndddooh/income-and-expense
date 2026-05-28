import Foundation

struct DefaultIncome: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let payDay: Int
    let method: Int
    let methodName: String
    let account: EmbeddedAccount
    let amount: Int
    let formedAmount: String
    let state: InexState
    let stateLabel: String
    let months: [Int]

    enum CodingKeys: String, CodingKey {
        case id, name, method, account, amount, state, months
        case payDay = "pay_day"
        case methodName = "method_name"
        case formedAmount = "formed_amount"
        case stateLabel = "state_label"
    }
}

struct DefaultIncomeInput: Codable {
    let name: String
    let payDay: Int
    let method: Int
    let amount: Int
    let state: InexState
    let months: [Int]

    enum CodingKeys: String, CodingKey {
        case name, method, amount, state, months
        case payDay = "pay_day"
    }
}
