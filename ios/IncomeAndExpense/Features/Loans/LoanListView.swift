import SwiftUI

struct LoanListView: View {
    @State private var store = LoanStore()
    @State private var showingNewForm = false
    @State private var editingLoan: Loan?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ScreenHeading("ローン")
                    .padding(.horizontal, 4)

                listCard

                YutoriPillButton(title: "＋ ローンを追加") { showingNewForm = true }

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

    @ViewBuilder
    private var listCard: some View {
        if store.loans.isEmpty {
            VStack {
                PlaceholderRow(kind: store.isLoading
                    ? .loading
                    : .empty(icon: "creditcard", message: "ローンの登録がありません"))
            }
            .frame(maxWidth: .infinity)
            .yutoriCard()
        } else {
            VStack(spacing: 0) {
                ForEach(Array(store.loans.enumerated()), id: \.element.id) { index, loan in
                    Button {
                        editingLoan = loan
                    } label: {
                        LoanRowView(loan: loan)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            Task { try? await store.delete(id: loan.id) }
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                    }
                    if index < store.loans.count - 1 {
                        Rectangle()
                            .fill(Palette.rowSeparator)
                            .frame(height: 1)
                    }
                }
            }
            .yutoriCard()
        }
    }
}
