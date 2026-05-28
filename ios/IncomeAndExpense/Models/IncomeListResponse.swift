import Foundation

struct IncomeListResponse: Codable {
    let results: [Income]
    let prevBalance: Int

    enum CodingKeys: String, CodingKey {
        case results
        case prevBalance = "prev_balance"
    }
}

struct AddDefaultsResponse: Codable {
    let added: Int
}
