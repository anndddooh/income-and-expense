import Foundation
import Observation

@Observable
final class DashboardViewModel {
    var trends: [TrendMonth] = []
    var currentIncome: Int = 0
    var currentExpense: Int = 0
    var prevBalance: Int = 0
    var isLoading: Bool = false
    var errorMessage: String? = nil

    func fetch(year: Int, month: Int) async {
        isLoading = true
        defer { isLoading = false }

        let queryItems = [
            URLQueryItem(name: "year", value: String(year)),
            URLQueryItem(name: "month", value: String(month)),
        ]

        async let incomeFetch: IncomeListResponse = APIClient.shared.request(
            APIEndpoint(path: "/incomes/", queryItems: queryItems)
        )
        async let expenseFetch: ExpenseListResponse = APIClient.shared.request(
            APIEndpoint(path: "/expenses/", queryItems: queryItems)
        )
        async let trendFetch: TrendResponse = APIClient.shared.request(
            APIEndpoint(
                path: "/trends/",
                queryItems: [
                    URLQueryItem(name: "months", value: "12"),
                    URLQueryItem(name: "end_year", value: String(year)),
                    URLQueryItem(name: "end_month", value: String(month)),
                ]
            )
        )

        do {
            let (inc, exp, trend) = try await (incomeFetch, expenseFetch, trendFetch)
            currentIncome = inc.results.reduce(0) { $0 + $1.amount }
            currentExpense = exp.results.reduce(0) { $0 + $1.amount }
            prevBalance = inc.prevBalance
            trends = trend.months
            errorMessage = nil
        } catch {
            errorMessage = (error as? AppError)?.errorDescription ?? error.localizedDescription
        }
    }

    var currentBalance: Int {
        currentIncome - currentExpense
    }
}
