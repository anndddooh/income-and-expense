import Foundation

struct ExpenseListResponse: Codable {
    let results: [Expense]
    let balance: Int
}
