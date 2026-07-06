import SwiftUI

struct LoanListView: View {
    @State private var store = LoanStore()
    @State private var showingNewForm = false
    @State private var editingLoan: Loan?

    var body: some View {
        List {
            Section {
                ScreenHeading("ローン")
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 8, leading: 4, bottom: 8, trailing: 4))

            Section {
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
                    .listRowBackground(Palette.card)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            Task { try? await store.delete(id: loan.id) }
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                    }
                }
            }
            .listRowSeparatorTint(Palette.rowSeparator)

            Section {
                YutoriPillButton(title: "＋ ローンを追加") { showingNewForm = true }
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 8, leading: 4, bottom: 12, trailing: 4))

            if let error = store.errorMessage {
                Section {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(Palette.expense)
                }
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Palette.background)
        .refreshable {
            await store.fetch()
        }
        .task {
            await store.fetch()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingNewForm = true
                } label: {
                    Image(systemName: "plus")
                }
                .tint(Palette.primaryStrong)
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
