import Foundation

struct ScenarioItem: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let payDay: Int
    let method: Int?
    let methodName: String?
    let amount: Int
    let category: ExpenseCategory
    let categoryLabel: String
    let isRequired: Bool
    let isEnabled: Bool
    let months: [Int]

    enum CodingKeys: String, CodingKey {
        case id, name, method, amount, category, months
        case payDay = "pay_day"
        case methodName = "method_name"
        case categoryLabel = "category_label"
        case isRequired = "is_required"
        case isEnabled = "is_enabled"
    }
}

struct ScenarioItemInput: Codable {
    let scenario: Int
    let name: String
    let payDay: Int
    let method: Int?
    let amount: Int
    let category: ExpenseCategory
    let isRequired: Bool
    let isEnabled: Bool
    let months: [Int]

    enum CodingKeys: String, CodingKey {
        case scenario, name, method, amount, category, months
        case payDay = "pay_day"
        case isRequired = "is_required"
        case isEnabled = "is_enabled"
    }
}

struct ScenarioItemPatch: Codable {
    let isEnabled: Bool?

    enum CodingKeys: String, CodingKey {
        case isEnabled = "is_enabled"
    }
}

struct Scenario: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let note: String
    let createdAt: String
    let updatedAt: String
    let items: [ScenarioItem]
    let itemCount: Int

    enum CodingKeys: String, CodingKey {
        case id, name, note, items
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case itemCount = "item_count"
    }
}

struct ScenarioInput: Codable {
    let name: String
    let note: String
}

struct ScenarioSummary: Codable {
    let mode: String  // "monthly" or "yearly"
    let month: Int?
    let income: Int
    let fixed: Int
    let variable: Int
    let oneTime: Int
    let totalExpense: Int
    let required: Int
    let optional: Int
    let balance: Int

    enum CodingKeys: String, CodingKey {
        case mode, month, income, fixed, variable, required, optional, balance
        case oneTime = "one_time"
        case totalExpense = "total_expense"
    }
}

struct HistoryAverage: Codable {
    let name: String
    let months: Int
    let average: Int
    let count: Int
}
