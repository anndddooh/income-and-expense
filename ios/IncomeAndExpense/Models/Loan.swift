import Foundation

struct Loan: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let payDay: Int
    let firstYear: Int
    let firstMonth: Int
    let lastYear: Int
    let lastMonth: Int
    let method: Int
    let methodName: String
    let account: EmbeddedAccount
    let amountFirst: Int
    let amountFromSecond: Int
    let formedAmountFirst: String
    let formedAmountFromSecond: String
    let state: InexState
    let stateLabel: String

    enum CodingKeys: String, CodingKey {
        case id, name, method, account, state
        case payDay = "pay_day"
        case firstYear = "first_year"
        case firstMonth = "first_month"
        case lastYear = "last_year"
        case lastMonth = "last_month"
        case methodName = "method_name"
        case amountFirst = "amount_first"
        case amountFromSecond = "amount_from_second"
        case formedAmountFirst = "formed_amount_first"
        case formedAmountFromSecond = "formed_amount_from_second"
        case stateLabel = "state_label"
    }
}

struct LoanInput: Codable {
    let name: String
    let payDay: Int
    let firstYear: Int
    let firstMonth: Int
    let lastYear: Int
    let lastMonth: Int
    let method: Int
    let amountFirst: Int
    let amountFromSecond: Int
    let state: InexState

    enum CodingKeys: String, CodingKey {
        case name, method, state
        case payDay = "pay_day"
        case firstYear = "first_year"
        case firstMonth = "first_month"
        case lastYear = "last_year"
        case lastMonth = "last_month"
        case amountFirst = "amount_first"
        case amountFromSecond = "amount_from_second"
    }
}
