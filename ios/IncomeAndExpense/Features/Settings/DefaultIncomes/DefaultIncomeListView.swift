import SwiftUI

struct DefaultIncomeListView: View {
    @State private var store = DefaultIncomeStore()
    @State private var showingNewForm = false
    @State private var editingItem: DefaultIncome?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ScreenHeading("デフォルト収入")
                    .padding(.horizontal, 4)

                listCard

                YutoriPillButton(title: "＋ デフォルト収入を追加", kind: .outline) { showingNewForm = true }

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
            DefaultIncomeFormView(
                viewModel: DefaultIncomeFormViewModel(item: nil, store: store)
            ) {
                Task { await store.fetch() }
            }
        }
        .sheet(item: $editingItem) { item in
            DefaultIncomeFormView(
                viewModel: DefaultIncomeFormViewModel(item: item, store: store)
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
                    : .empty(icon: "arrow.down.circle", message: "デフォルト収入が登録されていません"))
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

    private func row(_ item: DefaultIncome) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(item.name)
                    .font(.yutori(15, weight: .bold))
                    .foregroundStyle(Palette.foreground)
                Spacer()
                StateBadge(state: item.state)
            }
            HStack(spacing: 6) {
                Text(verbatim: "毎月\(item.payDay)日 · \(item.methodName) · \(item.account.user) / \(item.account.bank)")
                    .font(.yutori(11.5))
                    .foregroundStyle(Palette.mutedForeground)
                Spacer()
                Text(item.amount.yenString)
                    .font(.yutori(12.5, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(Palette.income)
            }
            Text(monthsLabel(item.months))
                .font(.yutori(11))
                .foregroundStyle(Palette.mutedForeground)
        }
    }

    private func monthsLabel(_ months: [Int]) -> String {
        if months.count == 12 { return "毎月" }
        return months.map { "\($0)月" }.joined(separator: " ")
    }
}
