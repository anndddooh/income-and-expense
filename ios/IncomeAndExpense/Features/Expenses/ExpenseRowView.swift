import SwiftUI

struct ExpenseRowView: View {
    let expense: Expense

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(expense.name)
                    .font(.body)
                    .fontWeight(.medium)
                Text(verbatim: expense.payDate.japaneseMonthDay)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(verbatim: "\(expense.methodName) · \(expense.account.user) / \(expense.account.bank)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 4) {
                Text(expense.amount.yenString)
                    .font(.callout.weight(.semibold))
                    .monospacedDigit()
                StateBadge(state: expense.state)
            }
        }
        .padding(.vertical, 2)
    }
}
