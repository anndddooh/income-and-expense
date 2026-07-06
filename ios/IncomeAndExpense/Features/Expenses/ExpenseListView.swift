import SwiftUI

struct ExpenseListView: View {
    @State private var store = ExpenseStore()
    @State private var stateFilter = StateFilterStorage(key: "inex.expenseList.stateFilter")
    @State private var showingNewForm = false
    @State private var editingExpense: Expense?
    @State private var showingDefaultsConfirm = false
    @State private var addedCount: Int? = nil
    private let monthStore = MonthStore.shared

    var body: some View {
        @Bindable var stateFilter = stateFilter
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ScreenHeading("支出")
                    .padding(.horizontal, 4)

                StateFilterChips(selected: $stateFilter.selected)
                    .padding(.horizontal, 4)

                listCard

                totalsLine
                    .padding(.horizontal, 6)

                YutoriPillButton(title: "＋ 支出を追加") { showingNewForm = true }

                if let error = store.errorMessage {
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

    @ViewBuilder
    private var listCard: some View {
        if store.expenses.isEmpty {
            VStack {
                PlaceholderRow(kind: store.isLoading
                    ? .loading
                    : .empty(icon: "tray", message: "支出の記録がありません"))
            }
            .frame(maxWidth: .infinity)
            .yutoriCard()
        } else if visibleExpenses.isEmpty {
            VStack {
                PlaceholderRow(
                    kind: .empty(
                        icon: "line.3.horizontal.decrease.circle",
                        message: "フィルター条件に一致する支出はありません"
                    )
                )
            }
            .frame(maxWidth: .infinity)
            .yutoriCard()
        } else {
            VStack(spacing: 0) {
                ForEach(Array(visibleExpenses.enumerated()), id: \.element.id) { index, expense in
                    Button {
                        editingExpense = expense
                    } label: {
                        ExpenseRowView(expense: expense)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            Task { try? await store.delete(id: expense.id) }
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                    }
                    if index < visibleExpenses.count - 1 {
                        Rectangle()
                            .fill(Palette.rowSeparator)
                            .frame(height: 1)
                    }
                }
            }
            .yutoriCard()
        }
    }

    private var totalsLine: some View {
        HStack {
            HStack(spacing: 5) {
                Text("当月支出(\(store.expenses.count)件)")
                    .foregroundStyle(Palette.mutedForeground)
                Text(currentExpenseTotal.yenString)
                    .fontWeight(.heavy)
                    .monospacedDigit()
                    .foregroundStyle(Palette.foreground)
            }
            Spacer()
            HStack(spacing: 5) {
                Text("当月残高")
                    .foregroundStyle(Palette.mutedForeground)
                Text(store.balance.yenString)
                    .fontWeight(.heavy)
                    .monospacedDigit()
                    .foregroundStyle(store.balance < 0 ? Palette.expense : Palette.foreground)
            }
        }
        .font(.yutori(12.5))
    }

    private var monthKey: String {
        "\(monthStore.year)-\(monthStore.month)"
    }

    private var currentExpenseTotal: Int {
        store.expenses.reduce(0) { $0 + $1.amount }
    }

    private var visibleExpenses: [Expense] {
        store.expenses.filter { stateFilter.selected.contains($0.state) }
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
