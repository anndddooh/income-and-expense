import SwiftUI

struct ExpenseRowView: View {
    let expense: Expense

    var body: some View {
        HStack(spacing: 11) {
            VStack(alignment: .leading, spacing: 1) {
                Text(expense.name)
                    .font(.yutori(15, weight: .bold))
                    .foregroundStyle(Palette.foreground)
                Text(verbatim: "\(expense.payDate.japaneseDay) · \(expense.methodName) · \(expense.account.user) / \(expense.account.bank)")
                    .font(.yutori(11.5))
                    .foregroundStyle(Palette.mutedForeground)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 3) {
                Text(expense.amount.yenString)
                    .font(.yutori(14.5, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(Palette.foreground)
                StateBadge(state: expense.state)
            }
        }
        .padding(.vertical, 2)
    }
}
