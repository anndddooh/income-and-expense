import Foundation
import Observation

@Observable
final class LoanStore {
    var loans: [Loan] = []
    var isLoading: Bool = false
    var errorMessage: String? = nil

    func fetch() async {
        isLoading = true
        defer { isLoading = false }
        do {
            loans = try await APIClient.shared.request(
                APIEndpoint(path: "/loans/")
            )
            errorMessage = nil
        } catch {
            errorMessage = (error as? AppError)?.errorDescription ?? error.localizedDescription
        }
    }

    func delete(id: Int) async throws {
        try await APIClient.shared.requestVoid(
            APIEndpoint(path: "/loans/\(id)/", method: .delete)
        )
        loans.removeAll { $0.id == id }
    }

    func create(_ input: LoanInput) async throws -> Loan {
        let body = try JSONCoders.encoder.encode(input)
        return try await APIClient.shared.request(
            APIEndpoint(path: "/loans/", method: .post, body: body)
        )
    }

    func update(id: Int, _ input: LoanInput) async throws -> Loan {
        let body = try JSONCoders.encoder.encode(input)
        return try await APIClient.shared.request(
            APIEndpoint(path: "/loans/\(id)/", method: .put, body: body)
        )
    }
}
