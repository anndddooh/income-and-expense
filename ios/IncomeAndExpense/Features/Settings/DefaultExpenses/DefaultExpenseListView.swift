import SwiftUI

struct DefaultExpenseListView: View {
    @State private var store = DefaultExpenseStore()
    @State private var showingNewForm = false
    @State private var editingItem: DefaultExpense?

    var body: some View {
        List {
            if store.items.isEmpty {
                PlaceholderRow(kind: store.isLoading
                    ? .loading
                    : .empty(icon: "arrow.up.circle", message: "デフォルト支出が登録されていません"))
            }
            ForEach(store.items) { item in
                Button {
                    editingItem = item
                } label: {
                    row(item)
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        Task { try? await store.delete(id: item.id) }
                    } label: {
                        Label("削除", systemImage: "trash")
                    }
                }
            }

            if let error = store.errorMessage {
                Section {
                    Text(error).font(.footnote).foregroundStyle(.red)
                }
            }
        }
        .refreshable { await store.fetch() }
        .task { await store.fetch() }
        .navigationTitle("デフォルト支出")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingNewForm = true } label: { Image(systemName: "plus") }
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

    private func row(_ item: DefaultExpense) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(item.name).font(.body)
                Spacer()
                StateBadge(state: item.state)
            }
            HStack(spacing: 6) {
                Text(verbatim: "毎月\(item.payDay)日 · \(item.methodName) · \(item.account.user) / \(item.account.bank)")
                    .font(.caption).foregroundStyle(.secondary)
                Spacer()
                Text(item.amount.yenString)
                    .font(.caption.monospacedDigit())
            }
            Text(monthsLabel(item.months))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func monthsLabel(_ months: [Int]) -> String {
        if months.count == 12 { return "毎月" }
        return months.map { "\($0)月" }.joined(separator: " ")
    }
}
