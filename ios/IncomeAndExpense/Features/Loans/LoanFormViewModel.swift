import Foundation
import Observation

@Observable
final class LoanFormViewModel {
    var name: String = ""
    var payDay: Int = 1
    var firstYear: Int = Calendar.current.component(.year, from: Date())
    var firstMonth: Int = Calendar.current.component(.month, from: Date())
    var lastYear: Int = Calendar.current.component(.year, from: Date()) + 1
    var lastMonth: Int = Calendar.current.component(.month, from: Date())
    var methodID: Int? = nil
    var amountFirst: String = ""
    var amountFromSecond: String = ""
    var state: InexState = .undecided
    var errorMessage: String? = nil
    var isSaving: Bool = false

    let original: Loan?
    private let store: LoanStore

    init(loan: Loan? = nil, store: LoanStore) {
        self.original = loan
        self.store = store
        if let loan {
            name = loan.name
            payDay = loan.payDay
            firstYear = loan.firstYear
            firstMonth = loan.firstMonth
            lastYear = loan.lastYear
            lastMonth = loan.lastMonth
            methodID = loan.method
            amountFirst = String(loan.amountFirst)
            amountFromSecond = String(loan.amountFromSecond)
            state = loan.state
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
        guard let firstAmount = Int(amountFirst), firstAmount >= 0,
              let secondAmount = Int(amountFromSecond), secondAmount >= 0 else {
            errorMessage = "金額は0以上の半角数字で入力してください"
            return false
        }
        guard (firstYear, firstMonth) <= (lastYear, lastMonth) else {
            errorMessage = "終了年月は開始年月より後にしてください"
            return false
        }

        isSaving = true
        defer { isSaving = false }
        errorMessage = nil

        let input = LoanInput(
            name: trimmed,
            payDay: payDay,
            firstYear: firstYear, firstMonth: firstMonth,
            lastYear: lastYear, lastMonth: lastMonth,
            method: methodID,
            amountFirst: firstAmount,
            amountFromSecond: secondAmount,
            state: state
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
