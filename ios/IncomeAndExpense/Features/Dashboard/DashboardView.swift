import SwiftUI

struct DashboardView: View {
    @State private var viewModel = DashboardViewModel()
    private let monthStore = MonthStore.shared

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                LazyVGrid(columns: columns, spacing: 12) {
                    SummaryCard(
                        title: "収入", amount: viewModel.currentIncome,
                        tint: Palette.income, systemImage: "arrow.down.circle.fill"
                    )
                    SummaryCard(
                        title: "支出", amount: viewModel.currentExpense,
                        tint: Palette.expense, systemImage: "arrow.up.circle.fill"
                    )
                    SummaryCard(
                        title: "前月繰越", amount: viewModel.prevBalance,
                        tint: .secondary, systemImage: "clock.arrow.circlepath"
                    )
                    SummaryCard(
                        title: "今月収支", amount: viewModel.currentBalance,
                        tint: Palette.amount(viewModel.currentBalance),
                        systemImage: "yensign.circle.fill"
                    )
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 10) {
                    Text("収支トレンド")
                        .font(.headline)
                    Text("直近12ヶ月")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TrendChart(months: viewModel.trends)
                        .frame(height: 220)
                        .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal)

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(Palette.expense)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .refreshable {
            await viewModel.fetch(year: monthStore.year, month: monthStore.month)
        }
        .task(id: monthKey) {
            await viewModel.fetch(year: monthStore.year, month: monthStore.month)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                MonthPicker(store: monthStore)
            }
        }
    }

    private var monthKey: String { "\(monthStore.year)-\(monthStore.month)" }
}
