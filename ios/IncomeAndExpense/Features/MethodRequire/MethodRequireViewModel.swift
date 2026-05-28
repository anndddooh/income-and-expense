import Foundation
import Observation

@Observable
final class MethodRequireViewModel {
    var response: MethodRequireResponse? = nil
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var lastUpdated: Int? = nil

    func fetch(year: Int, month: Int) async {
        isLoading = true
        defer { isLoading = false }
        do {
            response = try await APIClient.shared.request(
                APIEndpoint(
                    path: "/method_require/",
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

    func done(methodID: Int, year: Int, month: Int) async {
        do {
            let result: DoneResponse = try await APIClient.shared.request(
                APIEndpoint(
                    path: "/methods/\(methodID)/done/",
                    method: .post,
                    queryItems: [
                        URLQueryItem(name: "year", value: String(year)),
                        URLQueryItem(name: "month", value: String(month)),
                    ]
                )
            )
            lastUpdated = result.updated
            await fetch(year: year, month: month)
        } catch {
            errorMessage = (error as? AppError)?.errorDescription ?? error.localizedDescription
        }
    }
}
