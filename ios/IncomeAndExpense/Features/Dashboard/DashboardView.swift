import SwiftUI

struct DashboardView: View {
    @State private var viewModel = DashboardViewModel()
    @State private var expenseStore = ExpenseStore()
    @State private var incomeStore = IncomeStore()
    @State private var showingExpenseForm = false
    @State private var showingIncomeForm = false
    private let monthStore = MonthStore.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ScreenHeading("ホーム")
                    .padding(.bottom, 2)

                heroCard
                quickActions
                chartCard
                kpiCards

                if let error = viewModel.errorMessage {
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
        .sheet(isPresented: $showingExpenseForm) {
            ExpenseFormView(
                viewModel: ExpenseFormViewModel(expense: nil, store: expenseStore)
            ) {
                Task { await viewModel.fetch(year: monthStore.year, month: monthStore.month) }
            }
        }
        .sheet(isPresented: $showingIncomeForm) {
            IncomeFormView(
                viewModel: IncomeFormViewModel(income: nil, store: incomeStore)
            ) {
                Task { await viewModel.fetch(year: monthStore.year, month: monthStore.month) }
            }
        }
    }

    // MARK: - Hero

    private var heroCard: some View {
        let balance = viewModel.currentBalance
        let isPositive = balance >= 0
        let prefix = isPositive ? "＋" : "−"
        return VStack(alignment: .leading, spacing: 0) {
            Text(verbatim: "\(monthStore.month)月の収支")
                .font(.yutori(13))
                .foregroundStyle(Palette.mutedForeground)
            Text(verbatim: "\(prefix)\(abs(balance).yenString)")
                .font(.yutori(36, weight: .heavy))
                .monospacedDigit()
                .foregroundStyle(isPositive ? Palette.income : Palette.expense)
                .padding(.top, 4)
            HStack(spacing: 18) {
                breakdown(label: "収入", value: viewModel.currentIncome)
                breakdown(label: "支出", value: viewModel.currentExpense)
            }
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .yutoriCard()
    }

    private func breakdown(label: String, value: Int) -> some View {
        HStack(spacing: 5) {
            Text(label).foregroundStyle(Palette.mutedForeground)
            Text(value.yenString)
                .fontWeight(.bold)
                .monospacedDigit()
                .foregroundStyle(Palette.foreground)
        }
        .font(.yutori(12))
    }

    // MARK: - Quick actions

    private var quickActions: some View {
        HStack(spacing: 12) {
            YutoriPillButton(title: "＋ 支出") { showingExpenseForm = true }
            YutoriPillButton(title: "＋ 収入", kind: .outline) { showingIncomeForm = true }
        }
    }

    // MARK: - Chart

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("月ごとのながれ")
                    .font(.yutori(15, weight: .heavy))
                    .foregroundStyle(Palette.foreground)
                Spacer()
                Text("直近12ヶ月")
                    .font(.yutori(11))
                    .foregroundStyle(Palette.mutedForeground)
            }
            TrendChart(months: viewModel.trends)
                .frame(height: 170)
                .padding(.top, 12)
        }
        .padding(16)
        .yutoriCard()
    }

    // MARK: - KPI

    private var kpiCards: some View {
        HStack(spacing: 12) {
            kpiCard(
                label: "口座残高合計",
                value: viewModel.balanceSum.yenStringOrDash,
                color: Palette.foreground
            )
            kpiCard(
                label: "不足額",
                value: viewModel.shortfall.yenStringOrDash,
                color: (viewModel.shortfall ?? 0) > 0 ? Palette.expense : Palette.income
            )
        }
    }

    private func kpiCard(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.yutori(11.5))
                .foregroundStyle(Palette.mutedForeground)
            Text(value)
                .font(.yutori(17, weight: .heavy))
                .monospacedDigit()
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .yutoriCard(radius: 16)
    }

    private var monthKey: String { "\(monthStore.year)-\(monthStore.month)" }
}
