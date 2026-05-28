import SwiftUI

struct IncomeRowView: View {
    let income: Income

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(income.name)
                    .font(.body)
                    .fontWeight(.medium)
                Text(verbatim: income.payDate.japaneseMonthDay)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(verbatim: "\(income.methodName) · \(income.account.user) / \(income.account.bank)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 4) {
                Text(income.amount.yenString)
                    .font(.callout.weight(.semibold))
                    .monospacedDigit()
                StateBadge(state: income.state)
            }
        }
        .padding(.vertical, 2)
    }
}
