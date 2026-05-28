import Foundation
import Observation

enum TemplateDateType: String, Codable {
    case today
    case later
}

struct TemplateExpense: Codable, Identifiable, Hashable {
    let id: Int
    let templateName: String
    let name: String
    let dateType: TemplateDateType
    /// `date_type` が `today` のテンプレートでは null になるためオプショナル。
    let payDay: Int?
    let limitDayOfThisMonth: Int?
    let method: Int
    let methodName: String
    let state: InexState
    let payDate: Date

    enum CodingKeys: String, CodingKey {
        case id, name, method, state
        case templateName = "template_name"
        case dateType = "date_type"
        case payDay = "pay_day"
        case limitDayOfThisMonth = "limit_day_of_this_month"
        case methodName = "method_name"
        case payDate = "pay_date"
    }
}

/// 支出テンプレート一覧の取得ストア。MethodsStore と同じ「一度取れば使い回す」方針。
@Observable
final class TemplateExpensesStore {
    static let shared = TemplateExpensesStore()

    var templates: [TemplateExpense] = []
    var isLoading: Bool = false

    private init() {}

    func loadIfNeeded() async {
        guard templates.isEmpty, !isLoading else { return }
        await reload()
    }

    func reload() async {
        isLoading = true
        defer { isLoading = false }
        do {
            templates = try await APIClient.shared.request(
                APIEndpoint(path: "/template_expenses/")
            )
        } catch {
            // 取得失敗時はサイレント、テンプレート無し扱いでフォームは通常利用可
        }
    }
}
