import SwiftUI

struct MethodRequireView: View {
    @State private var viewModel = MethodRequireViewModel()
    @State private var doneTarget: MethodRequireRow?
    private let monthStore = MonthStore.shared

    var body: some View {
        List {
            Section("サマリ") {
                LabeledContent("必要額合計") {
                    Text(verbatim: amountText(viewModel.response?.requireSum))
                        .font(.body.monospacedDigit())
                }
            }

            Section("支払方法別") {
                if let methods = viewModel.response?.methods, !methods.isEmpty {
                    ForEach(methods) { method in
                        methodRow(method)
                    }
                } else {
                    PlaceholderRow(kind: viewModel.isLoading
                        ? .loading
                        : .empty(icon: "creditcard", message: "データがありません"))
                }
            }

            if let error = viewModel.errorMessage {
                Section {
                    Text(error).font(.footnote).foregroundStyle(.red)
                }
            }
        }
        .refreshable {
            await viewModel.fetch(year: monthStore.year, month: monthStore.month)
        }
        .task(id: monthKey) {
            await viewModel.fetch(year: monthStore.year, month: monthStore.month)
        }
        .navigationTitle("支払方法別必要額")
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

    private func methodRow(_ method: MethodRequireRow) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(method.displayName).font(.body)
                Text(method.formedRequire)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if method.require > 0 {
                Button {
                    doneTarget = method
                } label: {
                    Label("完了", systemImage: "checkmark.circle.fill")
                        .labelStyle(.iconOnly)
                        .font(.title3)
                }
                .buttonStyle(.borderless)
                .foregroundStyle(Palette.income)
            }
        }
    }

    private func amountText(_ value: Int?) -> String {
        guard let value else { return "-" }
        return "¥\(value.formatted(.number.grouping(.automatic)))"
    }
}
