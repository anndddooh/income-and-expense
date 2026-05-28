import SwiftUI

struct AccountRequireView: View {
    @State private var viewModel = AccountRequireViewModel()
    private let monthStore = MonthStore.shared

    var body: some View {
        List {
            Section("サマリ") {
                LabeledContent("必要額合計") {
                    Text(verbatim: amountText(viewModel.response?.requireSum))
                        .font(.body.monospacedDigit())
                }
                LabeledContent("不足額合計") {
                    insufficientView(viewModel.response?.insufficientSum ?? 0)
                }
            }

            Section("口座別") {
                if let accounts = viewModel.response?.accounts, !accounts.isEmpty {
                    ForEach(accounts) { row in
                        accountRow(row)
                            .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
                    }
                } else {
                    PlaceholderRow(kind: viewModel.isLoading
                        ? .loading
                        : .empty(icon: "building.columns", message: "データがありません"))
                }
            }

            if let error = viewModel.errorMessage {
                Section {
                    Text(error).font(.footnote).foregroundStyle(.red)
                }
            }
        }
        .refreshable {
            await viewModel.fetch(year: monthStore.year, month: monthStore.month)
        }
        .task(id: monthKey) {
            await viewModel.fetch(year: monthStore.year, month: monthStore.month)
        }
        .navigationTitle("口座別必要額")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                MonthPicker(store: monthStore)
            }
        }
    }

    private var monthKey: String { "\(monthStore.year)-\(monthStore.month)" }

    private func accountRow(_ row: AccountRequireRow) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(row.bank).font(.body)
                    Text(row.user).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if row.isInsufficient {
                    Label("不足", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(Palette.expense)
                }
            }
            HStack {
                Text("残高")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(row.formedBalance)
                    .font(.caption.monospacedDigit())
                Spacer()
                Text("必要額")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(row.formedRequire)
                    .font(.caption.monospacedDigit())
            }
            if row.isInsufficient {
                HStack {
                    Spacer()
                    Text("不足: \(row.formedInsufficient)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(Palette.expense)
                }
            }
        }
    }

    private func amountText(_ value: Int?) -> String {
        guard let value else { return "-" }
        return "¥\(value.formatted(.number.grouping(.automatic)))"
    }

    private func insufficientView(_ value: Int) -> some View {
        Text(verbatim: amountText(value))
            .font(.body.monospacedDigit())
            .foregroundStyle(value == 0 ? Color.secondary : Color.red)
    }
}
