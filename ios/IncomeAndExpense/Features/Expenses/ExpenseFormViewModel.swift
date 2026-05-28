import Foundation
import Observation

@Observable
final class ExpenseFormViewModel {
    var name: String = ""
    var payDate: Date = Date()
    var methodID: Int? = nil
    var amount: String = ""
    var state: InexState = .undecided
    var memo: String = ""
    var errorMessage: String? = nil
    var isSaving: Bool = false

    let original: Expense?
    private let store: ExpenseStore

    init(expense: Expense? = nil, store: ExpenseStore) {
        self.original = expense
        self.store = store
        if let expense {
            name = expense.name
            payDate = expense.payDate
            methodID = expense.method
            amount = String(expense.amount)
            state = expense.state
            memo = expense.memo ?? ""
        }
    }

    var isEdit: Bool { original != nil }

    /// テンプレートの内容をフォームに反映する。金額・メモはテンプレートに無いため触らない。
    func applyTemplate(_ template: TemplateExpense) {
        name = template.name
        payDate = template.payDate
        methodID = template.method
        state = template.state
    }

    func save() async -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "名前を入力してください"
            return false
        }
        guard let methodID else {
            errorMessage = "支払方法を選択してください"
            return false
        }
        guard let amountInt = Int(amount), amountInt > 0 else {
            errorMessage = "金額は1以上の半角数字で入力してください"
            return false
        }

        isSaving = true
        defer { isSaving = false }
        errorMessage = nil

        let input = ExpenseInput(
            name: trimmedName,
            payDate: payDate,
            method: methodID,
            amount: amountInt,
            state: state,
            memo: memo.isEmpty ? nil : memo
        )

        do {
            if let original {
                _ = try await store.update(id: original.id, input)
            } else {
                _ = try await store.create(input)
            }
            return true
        } catch let error as AppError {
            errorMessage = error.errorDescription
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
