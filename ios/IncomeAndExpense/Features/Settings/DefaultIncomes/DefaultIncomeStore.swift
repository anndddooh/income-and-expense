import Foundation
import Observation

@Observable
final class DefaultIncomeStore {
    var items: [DefaultIncome] = []
    var isLoading: Bool = false
    var errorMessage: String? = nil

    func fetch() async {
        isLoading = true
        defer { isLoading = false }
        do {
            items = try await APIClient.shared.request(
                APIEndpoint(path: "/default_incomes/")
            )
            errorMessage = nil
        } catch {
            errorMessage = (error as? AppError)?.errorDescription ?? error.localizedDescription
        }
    }

    func delete(id: Int) async throws {
        try await APIClient.shared.requestVoid(
            APIEndpoint(path: "/default_incomes/\(id)/", method: .delete)
        )
        items.removeAll { $0.id == id }
    }

    func create(_ input: DefaultIncomeInput) async throws -> DefaultIncome {
        let body = try JSONCoders.encoder.encode(input)
        return try await APIClient.shared.request(
            APIEndpoint(path: "/default_incomes/", method: .post, body: body)
        )
    }

    func update(id: Int, _ input: DefaultIncomeInput) async throws -> DefaultIncome {
        let body = try JSONCoders.encoder.encode(input)
        return try await APIClient.shared.request(
            APIEndpoint(path: "/default_incomes/\(id)/", method: .put, body: body)
        )
    }
}
