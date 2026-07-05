import SwiftUI

struct IncomeRowView: View {
    let income: Income

    var body: some View {
        HStack(spacing: 11) {
            VStack(alignment: .leading, spacing: 1) {
                Text(income.name)
                    .font(.yutori(15, weight: .bold))
                    .foregroundStyle(Palette.foreground)
                Text(verbatim: "\(income.payDate.japaneseDay) · \(income.methodName) · \(income.account.user) / \(income.account.bank)")
                    .font(.yutori(11.5))
                    .foregroundStyle(Palette.mutedForeground)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 3) {
                Text(income.amount.yenString)
                    .font(.yutori(14.5, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(Palette.income)
                StateBadge(state: income.state)
            }
        }
        .padding(.vertical, 2)
    }
}
