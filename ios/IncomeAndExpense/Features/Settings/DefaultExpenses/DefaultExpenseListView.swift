import SwiftUI

struct DefaultExpenseListView: View {
    @State private var store = DefaultExpenseStore()
    @State private var showingNewForm = false
    @State private var editingItem: DefaultExpense?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ScreenHeading("デフォルト支出")
                    .padding(.horizontal, 4)

                listCard

                YutoriPillButton(title: "＋ デフォルト支出を追加") { showingNewForm = true }

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
        .refreshable { await store.fetch() }
        .task { await store.fetch() }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingNewForm = true } label: { Image(systemName: "plus") }
                    .tint(Palette.primaryStrong)
            }
        }
        .sheet(isPresented: $showingNewForm) {
            DefaultExpenseFormView(
                viewModel: DefaultExpenseFormViewModel(item: nil, store: store)
            ) {
                Task { await store.fetch() }
            }
        }
        .sheet(item: $editingItem) { item in
            DefaultExpenseFormView(
                viewModel: DefaultExpenseFormViewModel(item: item, store: store)
            ) {
                Task { await store.fetch() }
            }
        }
    }

    @ViewBuilder
    private var listCard: some View {
        if store.items.isEmpty {
            VStack {
                PlaceholderRow(kind: store.isLoading
                    ? .loading
                    : .empty(icon: "arrow.up.circle", message: "デフォルト支出が登録されていません"))
            }
            .frame(maxWidth: .infinity)
            .yutoriCard()
        } else {
            VStack(spacing: 0) {
                ForEach(Array(store.items.enumerated()), id: \.element.id) { index, item in
                    Button {
                        editingItem = item
                    } label: {
                        row(item)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            Task { try? await store.delete(id: item.id) }
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                    }
                    if index < store.items.count - 1 {
                        Rectangle()
                            .fill(Palette.rowSeparator)
                            .frame(height: 1)
                    }
                }
            }
            .yutoriCard()
        }
    }

    private func row(_ item: DefaultExpense) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(item.name)
                    .font(.yutori(15, weight: .bold))
                    .foregroundStyle(Palette.foreground)
                Spacer()
                StateBadge(state: item.state)
            }
            HStack(spacing: 6) {
                attributeBadge(item.categoryLabel, tint: categoryTint(item.category))
                attributeBadge(
                    item.isRequired ? "必須" : "任意",
                    tint: item.isRequired ? Palette.primaryStrong : Palette.mutedForeground
                )
                Spacer()
                Text(item.amount.yenString)
                    .font(.yutori(12.5, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(Palette.foreground)
            }
            Text(verbatim: "毎月\(item.payDay)日 · \(item.methodName) · \(item.account.user) / \(item.account.bank)")
                .font(.yutori(11.5))
                .foregroundStyle(Palette.mutedForeground)
            Text(monthsLabel(item.months))
                .font(.yutori(11))
                .foregroundStyle(Palette.mutedForeground)
        }
    }

    private func attributeBadge(_ text: String, tint: Color) -> some View {
        Text(text)
            .font(.yutori(11, weight: .bold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(tint.opacity(0.15), in: Capsule())
            .foregroundStyle(tint)
    }

    private func categoryTint(_ category: ExpenseCategory) -> Color {
        switch category {
        case .fixed: return Palette.stateDecided
        case .variable: return Palette.accent
        case .oneTime: return Palette.stateDone
        }
    }

    private func monthsLabel(_ months: [Int]) -> String {
        if months.count == 12 { return "毎月" }
        return months.map { "\($0)月" }.joined(separator: " ")
    }
}
