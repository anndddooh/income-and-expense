import SwiftUI

struct LoanListView: View {
    @State private var store = LoanStore()
    @State private var showingNewForm = false
    @State private var editingLoan: Loan?

    var body: some View {
        List {
            if store.loans.isEmpty {
                PlaceholderRow(kind: store.isLoading
                    ? .loading
                    : .empty(icon: "creditcard", message: "ローンの登録がありません"))
            }
            ForEach(store.loans) { loan in
                Button {
                    editingLoan = loan
                } label: {
                    LoanRowView(loan: loan)
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        Task { try? await store.delete(id: loan.id) }
                    } label: {
                        Label("削除", systemImage: "trash")
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
            await store.fetch()
        }
        .task {
            await store.fetch()
        }
        .navigationTitle("ローン")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingNewForm = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewForm) {
            LoanFormView(
                viewModel: LoanFormViewModel(loan: nil, store: store)
            ) {
                Task { await store.fetch() }
            }
        }
        .sheet(item: $editingLoan) { loan in
            LoanFormView(
                viewModel: LoanFormViewModel(loan: loan, store: store)
            ) {
                Task { await store.fetch() }
            }
        }
    }
}
