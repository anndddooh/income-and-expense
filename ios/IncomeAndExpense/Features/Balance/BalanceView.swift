import SwiftUI

struct BalanceView: View {
    @State private var viewModel = BalanceViewModel()
    @State private var editingAccount: BalanceAccount?
    private let monthStore = MonthStore.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                ScreenHeading("残高")

                summaryCard

                VStack(alignment: .leading, spacing: 8) {
                    GroupCaption("口座ごとの実残高")
                    accountsCard
                }

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

    private var summaryCard: some View {
        let diff = viewModel.response?.balanceDiff ?? 0
        return VStack(alignment: .leading, spacing: 0) {
            Text("実残高合計")
                .font(.yutori(12))
                .foregroundStyle(Palette.mutedForeground)
            Text(verbatim: amountText(viewModel.response?.balanceSum))
                .font(.yutori(30, weight: .heavy))
                .monospacedDigit()
                .foregroundStyle(Palette.foreground)
                .padding(.top, 4)
            HStack(spacing: 18) {
                metric(label: "DB残高(完了分)",
                       value: amountText(viewModel.response?.balanceOnDb),
                       color: Palette.foreground)
                metric(label: "差額",
                       value: amountText(diff),
                       color: diff == 0 ? Palette.income : Palette.expense)
            }
            .padding(.top, 10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .yutoriCard()
    }

    private func metric(label: String, value: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Text(label)
                .foregroundStyle(Palette.mutedForeground)
            Text(verbatim: value)
                .fontWeight(.bold)
                .monospacedDigit()
                .foregroundStyle(color)
        }
        .font(.yutori(12))
    }

    @ViewBuilder
    private var accountsCard: some View {
        if let accounts = viewModel.response?.accounts, !accounts.isEmpty {
            VStack(spacing: 0) {
                ForEach(Array(accounts.enumerated()), id: \.element.id) { index, account in
                    Button {
                        editingAccount = account
                    } label: {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(account.bank)
                                    .font(.yutori(15, weight: .bold))
                                    .foregroundStyle(Palette.foreground)
                                Text(account.user)
                                    .font(.yutori(11.5))
                                    .foregroundStyle(Palette.mutedForeground)
                            }
                            Spacer(minLength: 8)
                            Text(account.formedBalance)
                                .font(.yutori(15, weight: .bold))
                                .monospacedDigit()
                                .foregroundStyle(Palette.foreground)
                            Text("編集")
                                .font(.yutori(12, weight: .bold))
                                .foregroundStyle(Palette.primaryStrong)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .overlay(Capsule().stroke(Palette.accent, lineWidth: 1.5))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 13)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    if index < accounts.count - 1 {
                        Rectangle()
                            .fill(Palette.rowSeparator)
                            .frame(height: 1)
                    }
                }
            }
            .yutoriCard()
        } else {
            VStack {
                PlaceholderRow(kind: viewModel.isLoading
                    ? .loading
                    : .empty(icon: "building.columns", message: "口座がありません"))
            }
            .yutoriCard()
        }
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
                            .foregroundStyle(Palette.expense)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Palette.background)
            .navigationTitle("残高を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                        .fontWeight(.bold)
                        .tint(Palette.mutedForeground2)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .fontWeight(.bold)
                        .tint(Palette.primaryStrong)
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
