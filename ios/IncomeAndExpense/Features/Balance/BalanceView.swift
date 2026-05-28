import SwiftUI

struct BalanceView: View {
    @State private var viewModel = BalanceViewModel()
    @State private var editingAccount: BalanceAccount?
    private let monthStore = MonthStore.shared

    var body: some View {
        List {
            Section("残高サマリ") {
                LabeledContent("口座合計") {
                    Text(verbatim: amountText(viewModel.response?.balanceSum))
                        .font(.body.monospacedDigit())
                }
                LabeledContent("計算上の残高") {
                    Text(verbatim: amountText(viewModel.response?.balanceOnDb))
                        .font(.body.monospacedDigit())
                }
                LabeledContent("差額") {
                    diffView(viewModel.response?.balanceDiff ?? 0)
                }
            }

            Section("口座別") {
                if let accounts = viewModel.response?.accounts, !accounts.isEmpty {
                    ForEach(accounts) { account in
                        Button {
                            editingAccount = account
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(account.bank).font(.body)
                                    Text(account.user).font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(account.formedBalance)
                                    .font(.body.monospacedDigit())
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    PlaceholderRow(kind: viewModel.isLoading
                        ? .loading
                        : .empty(icon: "building.columns", message: "口座がありません"))
                }
            }

            if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
        }
        .refreshable {
            await viewModel.fetch(year: monthStore.year, month: monthStore.month)
        }
        .task(id: monthKey) {
            await viewModel.fetch(year: monthStore.year, month: monthStore.month)
        }
        .navigationTitle("残高")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                MonthPicker(store: monthStore)
            }
        }
        .sheet(item: $editingAccount) { account in
            BalanceEditSheet(account: account) { newBalance in
                await viewModel.updateBalance(
                    accountID: account.id,
                    balance: newBalance,
                    year: monthStore.year,
                    month: monthStore.month
                )
            }
        }
    }

    private var monthKey: String { "\(monthStore.year)-\(monthStore.month)" }

    private func diffView(_ diff: Int) -> some View {
        Text(verbatim: amountText(diff))
            .font(.body.monospacedDigit())
            .foregroundStyle(diff == 0 ? Color.secondary : Palette.expense)
    }

    private func amountText(_ value: Int?) -> String {
        guard let value else { return "-" }
        return "¥\(value.formatted(.number.grouping(.automatic)))"
    }
}

/// 口座残高を編集するシート。保存クロージャは成功時 nil、失敗時にエラー文言を返す。
private struct BalanceEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    let account: BalanceAccount
    let onSave: (Int) async -> String?

    @State private var amount: String = ""
    @State private var errorMessage: String?
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("銀行", value: account.bank)
                    LabeledContent("ユーザー", value: account.user)
                    TextField("残高", text: $amount)
                        .keyboardType(.numbersAndPunctuation)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("残高を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(isSaving)
                }
            }
        }
        .onAppear { amount = String(account.balance) }
    }

    private func save() {
        guard let value = Int(amount) else {
            errorMessage = "残高は半角数字で入力してください"
            return
        }
        isSaving = true
        errorMessage = nil
        Task {
            let error = await onSave(value)
            isSaving = false
            if let error {
                errorMessage = error
            } else {
                Haptics.success()
                dismiss()
            }
        }
    }
}
