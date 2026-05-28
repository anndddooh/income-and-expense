import Foundation
import Observation

@Observable
final class IncomeStore {
    var incomes: [Income] = []
    var prevBalance: Int = 0
    var isLoading: Bool = false
    var errorMessage: String? = nil

    func fetch(year: Int, month: Int) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let response: IncomeListResponse = try await APIClient.shared.request(
                APIEndpoint(
                    path: "/incomes/",
                    queryItems: [
                        URLQueryItem(name: "year", value: String(year)),
                        URLQueryItem(name: "month", value: String(month)),
                    ]
                )
            )
            incomes = response.results
            prevBalance = response.prevBalance
            errorMessage = nil
        } catch {
            errorMessage = (error as? AppError)?.errorDescription ?? error.localizedDescription
        }
    }

    func delete(id: Int) async throws {
        try await APIClient.shared.requestVoid(
            APIEndpoint(path: "/incomes/\(id)/", method: .delete)
        )
        incomes.removeAll { $0.id == id }
    }

    func create(_ input: IncomeInput) async throws -> Income {
        let body = try JSONCoders.encoder.encode(input)
        let income: Income = try await APIClient.shared.request(
            APIEndpoint(path: "/incomes/", method: .post, body: body)
        )
        return income
    }

    func update(id: Int, _ input: IncomeInput) async throws -> Income {
        let body = try JSONCoders.encoder.encode(input)
        let income: Income = try await APIClient.shared.request(
            APIEndpoint(path: "/incomes/\(id)/", method: .put, body: body)
        )
        return income
    }

    func addDefaults(year: Int, month: Int) async throws -> Int {
        let response: AddDefaultsResponse = try await APIClient.shared.request(
            APIEndpoint(
                path: "/incomes/add_defaults/",
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
