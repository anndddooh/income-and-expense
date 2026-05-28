import SwiftUI

struct ExpenseListView: View {
    @State private var store = ExpenseStore()
    @State private var showingNewForm = false
    @State private var editingExpense: Expense?
    @State private var showingDefaultsConfirm = false
    @State private var addedCount: Int? = nil
    private let monthStore = MonthStore.shared

    var body: some View {
        List {
            Section {
                LabeledContent("月末残高(見込)") {
                    Text(store.balance.yenString)
                        .font(.body.monospacedDigit())
                        .foregroundStyle(store.balance < 0 ? Palette.expense : .primary)
                }
            }

            Section("支出") {
                if store.expenses.isEmpty {
                    PlaceholderRow(kind: store.isLoading
                        ? .loading
                        : .empty(icon: "tray", message: "支出の記録がありません"))
                }
                ForEach(store.expenses) { expense in
                    Button {
                        editingExpense = expense
                    } label: {
                        ExpenseRowView(expense: expense)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            Task { try? await store.delete(id: expense.id) }
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                    }
                }
            }

            if let error = store.errorMessage {
                Section {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
        }
        .refreshable {
            await store.fetch(year: monthStore.year, month: monthStore.month)
        }
        .task(id: monthKey) {
            await store.fetch(year: monthStore.year, month: monthStore.month)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                MonthPicker(store: monthStore)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingNewForm = true
                    } label: {
                        Label("新しい支出", systemImage: "plus")
                    }
                    Button {
                        showingDefaultsConfirm = true
                    } label: {
                        Label("デフォルト支出を適用", systemImage: "square.stack.3d.down.right")
                    }
                    .disabled(!monthStore.isCurrentOrFutureMonth)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .confirmationDialog(
            "今月のデフォルト支出を追加しますか?",
            isPresented: $showingDefaultsConfirm,
            titleVisibility: .visible
        ) {
            Button("適用する") {
                Task { await applyDefaults() }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("登録済みのデフォルト支出のうち、まだ今月分が無いものを新規追加します。")
        }
        .alert(
            "追加完了",
            isPresented: Binding(
                get: { addedCount != nil },
                set: { if !$0 { addedCount = nil } }
            ),
            actions: {
                Button("OK") { addedCount = nil }
            },
            message: {
                Text("\(addedCount ?? 0)件追加しました。")
            }
        )
        .sheet(isPresented: $showingNewForm) {
            ExpenseFormView(
                viewModel: ExpenseFormViewModel(expense: nil, store: store)
            ) {
                Task {
                    await store.fetch(year: monthStore.year, month: monthStore.month)
                }
            }
        }
        .sheet(item: $editingExpense) { expense in
            ExpenseFormView(
                viewModel: ExpenseFormViewModel(expense: expense, store: store)
            ) {
                Task {
                    await store.fetch(year: monthStore.year, month: monthStore.month)
                }
            }
        }
    }

    private var monthKey: String {
        "\(monthStore.year)-\(monthStore.month)"
    }

    private func applyDefaults() async {
        do {
            let added = try await store.addDefaults(
                year: monthStore.year, month: monthStore.month
            )
            addedCount = added
            Haptics.success()
        } catch {
            store.errorMessage = (error as? AppError)?.errorDescription
                ?? error.localizedDescription
        }
    }
}
