import SwiftUI

struct DefaultIncomeListView: View {
    @State private var store = DefaultIncomeStore()
    @State private var showingNewForm = false
    @State private var editingItem: DefaultIncome?

    var body: some View {
        List {
            if store.items.isEmpty {
                PlaceholderRow(kind: store.isLoading
                    ? .loading
                    : .empty(icon: "arrow.down.circle", message: "デフォルト収入が登録されていません"))
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
        .navigationTitle("デフォルト収入")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingNewForm = true } label: { Image(systemName: "plus") }
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

    private func row(_ item: DefaultIncome) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(item.name).font(.body)
                Spacer()
                StateBadge(state: item.state)
            }
            HStack(spacing: 8) {
                Text(verbatim: "毎月\(item.payDay)日")
                    .font(.caption).foregroundStyle(.secondary)
                Text(item.methodName)
                    .font(.caption).foregroundStyle(.secondary)
                Text(verbatim: "\(item.account.user) / \(item.account.bank)")
                    .font(.caption2).foregroundStyle(.secondary)
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
