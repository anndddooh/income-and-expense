import Foundation
import Observation

@Observable
final class DefaultIncomeFormViewModel {
    var name: String = ""
    var payDay: Int = 1
    var methodID: Int? = nil
    var amount: String = ""
    var state: InexState = .undecided
    var months: [Int] = []
    var errorMessage: String? = nil
    var isSaving: Bool = false

    let original: DefaultIncome?
    private let store: DefaultIncomeStore

    init(item: DefaultIncome? = nil, store: DefaultIncomeStore) {
        self.original = item
        self.store = store
        if let item {
            name = item.name
            payDay = item.payDay
            methodID = item.method
            amount = String(item.amount)
            state = item.state
            months = item.months
        }
    }

    var isEdit: Bool { original != nil }

    func save() async -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
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
        guard !months.isEmpty else {
            errorMessage = "対象月を1つ以上選択してください"
            return false
        }

        isSaving = true
        defer { isSaving = false }
        errorMessage = nil

        let input = DefaultIncomeInput(
            name: trimmed, payDay: payDay, method: methodID,
            amount: amountInt, state: state, months: months.sorted()
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
