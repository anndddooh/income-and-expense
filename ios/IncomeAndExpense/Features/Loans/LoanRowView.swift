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
            Text(verbatim: "\(loan.firstYear)年\(loan.firstMonth)月 – \(loan.lastYear)年\(loan.lastMonth)月 · 毎月\(loan.payDay)日")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 6) {
                Text(verbatim: "\(loan.methodName) · \(loan.account.user) / \(loan.account.bank)")
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
