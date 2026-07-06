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
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ScreenHeading("収入")
                    .padding(.horizontal, 4)

                StateFilterChips(selected: $stateFilter.selected)
                    .padding(.horizontal, 4)

                listCard

                totalsLine
                    .padding(.horizontal, 6)

                YutoriPillButton(title: "＋ 収入を追加", kind: .outline) { showingNewForm = true }

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

    @ViewBuilder
    private var listCard: some View {
        if store.incomes.isEmpty {
            VStack {
                PlaceholderRow(kind: store.isLoading
                    ? .loading
                    : .empty(icon: "tray", message: "収入の記録がありません"))
            }
            .frame(maxWidth: .infinity)
            .yutoriCard()
        } else if visibleIncomes.isEmpty {
            VStack {
                PlaceholderRow(
                    kind: .empty(
                        icon: "line.3.horizontal.decrease.circle",
                        message: "フィルター条件に一致する収入はありません"
                    )
                )
            }
            .frame(maxWidth: .infinity)
            .yutoriCard()
        } else {
            VStack(spacing: 0) {
                ForEach(Array(visibleIncomes.enumerated()), id: \.element.id) { index, income in
                    Button {
                        editingIncome = income
                    } label: {
                        IncomeRowView(income: income)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            Task { try? await store.delete(id: income.id) }
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                    }
                    if index < visibleIncomes.count - 1 {
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
                Text("当月収入(\(store.incomes.count)件)")
                    .foregroundStyle(Palette.mutedForeground)
                Text(currentIncomeTotal.yenString)
                    .fontWeight(.heavy)
                    .monospacedDigit()
                    .foregroundStyle(Palette.foreground)
            }
            Spacer()
            HStack(spacing: 5) {
                Text("前月残高")
                    .foregroundStyle(Palette.mutedForeground)
                Text(store.prevBalance.yenString)
                    .fontWeight(.heavy)
                    .monospacedDigit()
                    .foregroundStyle(Palette.foreground)
            }
        }
        .font(.yutori(12.5))
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
