import Foundation

struct BalanceResponse: Codable {
    let accounts: [BalanceAccount]
    let balanceSum: Int
    let balanceOnDb: Int
    let balanceDiff: Int

    enum CodingKeys: String, CodingKey {
        case accounts
        case balanceSum = "balance_sum"
        case balanceOnDb = "balance_on_db"
        case balanceDiff = "balance_diff"
    }
}

struct BalanceAccount: Codable, Identifiable, Hashable {
    let id: Int
    let user: String
    let bank: String
    let balance: Int
    let formedBalance: String

    enum CodingKeys: String, CodingKey {
        case id, user, bank, balance
        case formedBalance = "formed_balance"
    }
}

struct AccountRequireResponse: Codable {
    let accounts: [AccountRequireRow]
    let requireSum: Int
    let insufficientSum: Int

    enum CodingKeys: String, CodingKey {
        case accounts
        case requireSum = "require_sum"
        case insufficientSum = "insufficient_sum"
    }
}

struct AccountRequireRow: Codable, Identifiable, Hashable {
    let id: Int
    let user: String
    let bank: String
    let balance: Int
    let formedBalance: String
    let require: Int
    let formedRequire: String
    let insufficientAmount: Int
    let formedInsufficient: String
    let isInsufficient: Bool

    enum CodingKeys: String, CodingKey {
        case id, user, bank, balance, require
        case formedBalance = "formed_balance"
        case formedRequire = "formed_require"
        case insufficientAmount = "insufficient_amount"
        case formedInsufficient = "formed_insufficient"
        case isInsufficient = "is_insufficient"
    }
}

struct MethodRequireResponse: Codable {
    let methods: [MethodRequireRow]
    let requireSum: Int

    enum CodingKeys: String, CodingKey {
        case methods
        case requireSum = "require_sum"
    }
}

struct MethodRequireRow: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let displayName: String
    let require: Int
    let formedRequire: String

    enum CodingKeys: String, CodingKey {
        case id, name, require
        case displayName = "display_name"
        case formedRequire = "formed_require"
    }
}

struct DoneResponse: Codable {
    let updated: Int
}

struct TrendResponse: Codable {
    let months: [TrendMonth]
}

struct TrendMonth: Codable, Hashable {
    let year: Int
    let month: Int
    let income: Int
    let expense: Int
}
