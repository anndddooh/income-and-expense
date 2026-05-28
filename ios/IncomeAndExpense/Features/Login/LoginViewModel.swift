import Foundation
import Observation

@Observable
final class LoginViewModel {
    var username: String = ""
    var password: String = ""
    var errorMessage: String? = nil
    var isLoading: Bool = false

    var canSubmit: Bool {
        !isLoading && !username.isEmpty && !password.isEmpty
    }

    func submit() async {
        guard canSubmit else { return }
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            try await AuthStore.shared.login(username: username, password: password)
        } catch let error as AppError {
            switch error {
            case .httpError(let status, _) where status == 401:
                errorMessage = "ユーザー名またはパスワードが違います"
            default:
                errorMessage = error.errorDescription
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
