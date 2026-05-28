import SwiftUI

struct LoanRowView: View {
    let loan: Loan

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(loan.name)
                    .font(.body)
                    .fontWeight(.medium)
                Spacer()
                StateBadge(state: loan.state)
            }
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.caption2)
                Text(verbatim: "\(loan.firstYear)/\(loan.firstMonth) – \(loan.lastYear)/\(loan.lastMonth)")
                Text(verbatim: "·")
                Text(verbatim: "毎月\(loan.payDay)日")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            HStack(spacing: 6) {
                Image(systemName: "creditcard")
                    .font(.caption2)
                Text(loan.methodName)
                Text(verbatim: "·")
                Text(verbatim: "\(loan.account.user) / \(loan.account.bank)")
                Spacer()
                Text(verbatim: "初回 \(loan.amountFirst.yenString)")
                    .monospacedDigit()
                Text(verbatim: "2回目〜 \(loan.amountFromSecond.yenString)")
                    .monospacedDigit()
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}
