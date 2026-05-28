import Foundation
import Observation

@Observable
final class DefaultExpenseStore {
    var items: [DefaultExpense] = []
    var isLoading: Bool = false
    var errorMessage: String? = nil

    func fetch() async {
        isLoading = true
        defer { isLoading = false }
        do {
            items = try await APIClient.shared.request(
                APIEndpoint(path: "/default_expenses/")
            )
            errorMessage = nil
        } catch {
            errorMessage = (error as? AppError)?.errorDescription ?? error.localizedDescription
        }
    }

    func delete(id: Int) async throws {
        try await APIClient.shared.requestVoid(
            APIEndpoint(path: "/default_expenses/\(id)/", method: .delete)
        )
        items.removeAll { $0.id == id }
    }

    func create(_ input: DefaultExpenseInput) async throws -> DefaultExpense {
        let body = try JSONCoders.encoder.encode(input)
        return try await APIClient.shared.request(
            APIEndpoint(path: "/default_expenses/", method: .post, body: body)
        )
    }

    func update(id: Int, _ input: DefaultExpenseInput) async throws -> DefaultExpense {
        let body = try JSONCoders.encoder.encode(input)
        return try await APIClient.shared.request(
            APIEndpoint(path: "/default_expenses/\(id)/", method: .put, body: body)
        )
    }
}
