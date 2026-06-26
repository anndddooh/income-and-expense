import SwiftUI

struct IncomeListView: View {
    @State private var store = IncomeStore()
    @State private var stateFilter = StateFilterStorage(key: "inex.incomeList.stateFilter")
    @State private var showingNewForm = false
    @State private var editingIncome: Income?
    @State private var showingDefaultsConfirm = false
    @State private var addedCount: Int? = nil
    private let monthStore = MonthStore.shared

    var body: some View {
        @Bindable var stateFilter = stateFilter
        List {
            Section {
                StateFilterChips(selected: $stateFilter.selected)
            }

            Section("収入") {
                if store.incomes.isEmpty {
                    PlaceholderRow(kind: store.isLoading
                        ? .loading
                        : .empty(icon: "tray", message: "収入の記録がありません"))
                } else if visibleIncomes.isEmpty {
                    PlaceholderRow(
                        kind: .empty(
                            icon: "line.3.horizontal.decrease.circle",
                            message: "フィルター条件に一致する収入はありません"
                        )
                    )
                }
                ForEach(visibleIncomes) { income in
                    Button {
                        editingIncome = income
                    } label: {
                        IncomeRowView(income: income)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            Task { try? await store.delete(id: income.id) }
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                    }
                }
            }

            Section {
                LabeledContent("前月残高") {
                    Text(store.prevBalance.yenString)
                        .font(.body.monospacedDigit())
                }
                LabeledContent("当月収入(\(store.incomes.count)件)") {
                    Text(currentIncomeTotal.yenString)
                        .font(.body.monospacedDigit())
                }
                LabeledContent("合計") {
                    Text((store.prevBalance + currentIncomeTotal).yenString)
                        .font(.body.monospacedDigit().weight(.semibold))
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
                        Label("新しい収入", systemImage: "plus")
                    }
                    Button {
                        showingDefaultsConfirm = true
                    } label: {
                        Label("デフォルト収入を適用", systemImage: "square.stack.3d.down.right")
                    }
                    .disabled(!monthStore.isCurrentOrFutureMonth)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .confirmationDialog(
            "今月のデフォルト収入を追加しますか?",
            isPresented: $showingDefaultsConfirm,
            titleVisibility: .visible
        ) {
            Button("適用する") {
                Task { await applyDefaults() }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("登録済みのデフォルト収入のうち、まだ今月分が無いものを新規追加します。")
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
            IncomeFormView(
                viewModel: IncomeFormViewModel(income: nil, store: store)
            ) {
                Task {
                    await store.fetch(year: monthStore.year, month: monthStore.month)
                }
            }
        }
        .sheet(item: $editingIncome) { income in
            IncomeFormView(
                viewModel: IncomeFormViewModel(income: income, store: store)
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

    private var currentIncomeTotal: Int {
        store.incomes.reduce(0) { $0 + $1.amount }
    }

    private var visibleIncomes: [Income] {
        store.incomes.filter { stateFilter.selected.contains($0.state) }
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
