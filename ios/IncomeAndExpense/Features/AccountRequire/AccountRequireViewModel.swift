import Foundation
import Observation

@Observable
final class AccountRequireViewModel {
    var response: AccountRequireResponse? = nil
    var isLoading: Bool = false
    var errorMessage: String? = nil

    func fetch(year: Int, month: Int) async {
        isLoading = true
        defer { isLoading = false }
        do {
            response = try await APIClient.shared.request(
                APIEndpoint(
                    path: "/account_require/",
                    queryItems: [
                        URLQueryItem(name: "year", value: String(year)),
                        URLQueryItem(name: "month", value: String(month)),
                    ]
                )
            )
            errorMessage = nil
        } catch {
            errorMessage = (error as? AppError)?.errorDescription ?? error.localizedDescription
        }
    }
}
