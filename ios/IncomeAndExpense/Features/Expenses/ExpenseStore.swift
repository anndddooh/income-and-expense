import Foundation
import Observation

@Observable
final class ExpenseStore {
    var expenses: [Expense] = []
    var balance: Int = 0
    var isLoading: Bool = false
    var errorMessage: String? = nil

    func fetch(year: Int, month: Int) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let response: ExpenseListResponse = try await APIClient.shared.request(
                APIEndpoint(
                    path: "/expenses/",
                    queryItems: [
                        URLQueryItem(name: "year", value: String(year)),
                        URLQueryItem(name: "month", value: String(month)),
                    ]
                )
            )
            expenses = response.results
            balance = response.balance
            errorMessage = nil
        } catch {
            errorMessage = (error as? AppError)?.errorDescription ?? error.localizedDescription
        }
    }

    func delete(id: Int) async throws {
        try await APIClient.shared.requestVoid(
            APIEndpoint(path: "/expenses/\(id)/", method: .delete)
        )
        expenses.removeAll { $0.id == id }
    }

    func create(_ input: ExpenseInput) async throws -> Expense {
        let body = try JSONCoders.encoder.encode(input)
        return try await APIClient.shared.request(
            APIEndpoint(path: "/expenses/", method: .post, body: body)
        )
    }

    func update(id: Int, _ input: ExpenseInput) async throws -> Expense {
        let body = try JSONCoders.encoder.encode(input)
        return try await APIClient.shared.request(
            APIEndpoint(path: "/expenses/\(id)/", method: .put, body: body)
        )
    }

    func addDefaults(year: Int, month: Int) async throws -> Int {
        let response: AddDefaultsResponse = try await APIClient.shared.request(
            APIEndpoint(
                path: "/expenses/add_defaults/",
                method: .post,
                queryItems: [
                    URLQueryItem(name: "year", value: String(year)),
                    URLQueryItem(name: "month", value: String(month)),
                ]
            )
        )
        await fetch(year: year, month: month)
        return response.added
    }
}
