import Foundation

enum ExpenseCategory: Int, Codable, CaseIterable, Identifiable {
    case fixed = 1
    case variable = 2
    case oneTime = 3

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .fixed: return "固定費"
        case .variable: return "変動費"
        case .oneTime: return "単発"
        }
    }
}

struct DefaultExpense: Codable, Identifiable, Hashable {
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
    let category: ExpenseCategory
    let categoryLabel: String
    let isRequired: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, method, account, amount, state, months, category
        case payDay = "pay_day"
        case methodName = "method_name"
        case formedAmount = "formed_amount"
        case stateLabel = "state_label"
        case categoryLabel = "category_label"
        case isRequired = "is_required"
    }
}

struct DefaultExpenseInput: Codable {
    let name: String
    let payDay: Int
    let method: Int
    let amount: Int
    let state: InexState
    let months: [Int]
    let category: ExpenseCategory
    let isRequired: Bool

    enum CodingKeys: String, CodingKey {
        case name, method, amount, state, months, category
        case payDay = "pay_day"
        case isRequired = "is_required"
    }
}
