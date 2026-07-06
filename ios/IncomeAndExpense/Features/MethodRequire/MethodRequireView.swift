import SwiftUI

struct MethodRequireView: View {
    @State private var viewModel = MethodRequireViewModel()
    @State private var doneTarget: MethodRequireRow?
    private let monthStore = MonthStore.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ScreenHeading("支払方法別必要額")
                    .padding(.horizontal, 4)

                kpiCard(
                    label: "必要額合計",
                    value: amountText(viewModel.response?.requireSum)
                )

                listCard

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
        .confirmationDialog(
            "「\(doneTarget?.displayName ?? "")」の今月分を完了済みにしますか?",
            isPresented: Binding(
                get: { doneTarget != nil },
                set: { if !$0 { doneTarget = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("完了にする") {
                if let target = doneTarget {
                    Task {
                        await viewModel.done(
                            methodID: target.id,
                            year: monthStore.year,
                            month: monthStore.month
                        )
                        if viewModel.lastUpdated != nil {
                            Haptics.success()
                        }
                    }
                }
                doneTarget = nil
            }
            Button("キャンセル", role: .cancel) { doneTarget = nil }
        }
        .alert(
            "完了処理",
            isPresented: Binding(
                get: { viewModel.lastUpdated != nil },
                set: { if !$0 { viewModel.lastUpdated = nil } }
            ),
            actions: {
                Button("OK") { viewModel.lastUpdated = nil }
            },
            message: {
                Text("\(viewModel.lastUpdated ?? 0)件を完了にしました。")
            }
        )
    }

    private var monthKey: String { "\(monthStore.year)-\(monthStore.month)" }

    @ViewBuilder
    private var listCard: some View {
        if let methods = viewModel.response?.methods, !methods.isEmpty {
            VStack(spacing: 0) {
                ForEach(Array(methods.enumerated()), id: \.element.id) { index, method in
                    methodRow(method)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    if index < methods.count - 1 {
                        Rectangle()
                            .fill(Palette.rowSeparator)
                            .frame(height: 1)
                    }
                }
            }
            .yutoriCard()
        } else {
            VStack {
                PlaceholderRow(kind: viewModel.isLoading
                    ? .loading
                    : .empty(icon: "creditcard", message: "データがありません"))
            }
            .frame(maxWidth: .infinity)
            .yutoriCard()
        }
    }

    private func kpiCard(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.yutori(12))
                .foregroundStyle(Palette.mutedForeground)
            Spacer()
            Text(value)
                .font(.yutori(19, weight: .heavy))
                .monospacedDigit()
                .foregroundStyle(Palette.foreground)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .yutoriCard(radius: 16)
    }

    private func methodRow(_ method: MethodRequireRow) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(method.displayName)
                    .font(.yutori(15, weight: .bold))
                    .foregroundStyle(Palette.foreground)
                Text(method.formedRequire)
                    .font(.yutori(12.5, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(Palette.mutedForeground)
            }
            Spacer()
            if method.require > 0 {
                Button {
                    doneTarget = method
                } label: {
                    Text("一括完了")
                        .font(.yutori(12, weight: .bold))
                        .foregroundStyle(Palette.stateDone)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .overlay(Capsule().stroke(Palette.stateDone.opacity(0.5), lineWidth: 1.5))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func amountText(_ value: Int?) -> String {
        guard let value else { return "-" }
        return "¥\(value.formatted(.number.grouping(.automatic)))"
    }
}
