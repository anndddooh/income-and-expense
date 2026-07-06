import SwiftUI

struct AccountRequireView: View {
    @State private var viewModel = AccountRequireViewModel()
    private let monthStore = MonthStore.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ScreenHeading("口座別必要額")
                    .padding(.horizontal, 4)

                HStack(spacing: 12) {
                    kpiCard(
                        label: "必要額合計",
                        value: amountText(viewModel.response?.requireSum),
                        color: Palette.foreground
                    )
                    kpiCard(
                        label: "不足額合計",
                        value: amountText(viewModel.response?.insufficientSum),
                        color: (viewModel.response?.insufficientSum ?? 0) > 0 ? Palette.expense : Palette.income
                    )
                }

                listCard

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(Palette.expense)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(16)
        }
        .background(Palette.background)
        .refreshable {
            await viewModel.fetch(year: monthStore.year, month: monthStore.month)
        }
        .task(id: monthKey) {
            await viewModel.fetch(year: monthStore.year, month: monthStore.month)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                MonthPicker(store: monthStore)
            }
        }
    }

    private var monthKey: String { "\(monthStore.year)-\(monthStore.month)" }

    @ViewBuilder
    private var listCard: some View {
        if let accounts = viewModel.response?.accounts, !accounts.isEmpty {
            VStack(spacing: 0) {
                ForEach(Array(accounts.enumerated()), id: \.element.id) { index, row in
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(row.isInsufficient ? Palette.expense : Color.clear)
                            .frame(width: 3)
                        accountRow(row)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    if index < accounts.count - 1 {
                        Rectangle()
                            .fill(Palette.rowSeparator)
                            .frame(height: 1)
                    }
                }
            }
            .yutoriCard()
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        } else {
            VStack {
                PlaceholderRow(kind: viewModel.isLoading
                    ? .loading
                    : .empty(icon: "building.columns", message: "データがありません"))
            }
            .frame(maxWidth: .infinity)
            .yutoriCard()
        }
    }

    private func kpiCard(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.yutori(11.5))
                .foregroundStyle(Palette.mutedForeground)
            Text(value)
                .font(.yutori(17, weight: .heavy))
                .monospacedDigit()
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .yutoriCard(radius: 16)
    }

    private func accountRow(_ row: AccountRequireRow) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text(row.bank)
                        .font(.yutori(15, weight: .bold))
                        .foregroundStyle(Palette.foreground)
                    Text(row.user)
                        .font(.yutori(11.5))
                        .foregroundStyle(Palette.mutedForeground)
                }
                Spacer()
                if row.isInsufficient {
                    Label("不足", systemImage: "exclamationmark.triangle.fill")
                        .font(.yutori(11, weight: .bold))
                        .foregroundStyle(Palette.expense)
                }
            }
            HStack {
                Text("残高")
                    .font(.yutori(11.5))
                    .foregroundStyle(Palette.mutedForeground)
                Text(row.formedBalance)
                    .font(.yutori(12.5, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(Palette.foreground)
                Spacer()
                Text("必要額")
                    .font(.yutori(11.5))
                    .foregroundStyle(Palette.mutedForeground)
                Text(row.formedRequire)
                    .font(.yutori(12.5, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(Palette.foreground)
            }
            if row.isInsufficient {
                HStack {
                    Spacer()
                    Text("不足: \(row.formedInsufficient)")
                        .font(.yutori(12.5, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(Palette.expense)
                }
            }
        }
    }

    private func amountText(_ value: Int?) -> String {
        guard let value else { return "-" }
        return "¥\(value.formatted(.number.grouping(.automatic)))"
    }
}
