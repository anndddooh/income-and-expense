import Foundation
import Observation

@Observable
final class BalanceViewModel {
    var response: BalanceResponse? = nil
    var isLoading: Bool = false
    var errorMessage: String? = nil

    func fetch(year: Int, month: Int) async {
        isLoading = true
        defer { isLoading = false }
        do {
            response = try await APIClient.shared.request(
                APIEndpoint(
                    path: "/balance/",
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

    /// 口座残高を更新する。成功時は nil、失敗時はエラーメッセージを返す。
    /// 更新後は残高サマリを取り直して画面に反映する。
    func updateBalance(accountID: Int, balance: Int, year: Int, month: Int) async -> String? {
        do {
            let body = try JSONCoders.encoder.encode(AccountBalanceUpdate(balance: balance))
            try await APIClient.shared.requestVoid(
                APIEndpoint(path: "/accounts/\(accountID)/", method: .patch, body: body)
            )
            await fetch(year: year, month: month)
            return nil
        } catch {
            return (error as? AppError)?.errorDescription ?? error.localizedDescription
        }
    }
}

/// 口座残高の部分更新(PATCH /accounts/{id}/)用のリクエストボディ。
struct AccountBalanceUpdate: Encodable {
    let balance: Int
}
