import SwiftUI

struct ScenarioItemDraft: Identifiable {
    var id: Int { itemID ?? -1 }
    var itemID: Int?
    var name: String
    var payDay: Int
    var amount: String
    var category: ExpenseCategory
    var isRequired: Bool
    var isEnabled: Bool
    var months: [Int]

    static func empty() -> ScenarioItemDraft {
        ScenarioItemDraft(
            itemID: nil,
            name: "",
            payDay: 1,
            amount: "",
            category: .fixed,
            isRequired: true,
            isEnabled: true,
            months: Array(1...12)
        )
    }

    static func from(item: ScenarioItem) -> ScenarioItemDraft {
        ScenarioItemDraft(
            itemID: item.id,
            name: item.name,
            payDay: item.payDay,
            amount: String(item.amount),
            category: item.category,
            isRequired: item.isRequired,
            isEnabled: item.isEnabled,
            months: item.months
        )
    }
}

struct ScenarioItemEditView: View {
    @Environment(\.dismiss) private var dismiss
    @State var draft: ScenarioItemDraft
    let store: ScenarioDetailStore
    let onSaved: () -> Void
    @State private var historyAverage: HistoryAverage? = nil
    @State private var isSaving: Bool = false
    @State private var errorMessage: String? = nil

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("名称", text: $draft.name)
                    Picker("区分", selection: $draft.category) {
                        ForEach(ExpenseCategory.allCases) { c in
                            Text(c.label).tag(c)
                        }
                    }
                    TextField("金額", text: $draft.amount)
                        .keyboardType(.numberPad)
                    if draft.category == .variable, let avg = historyAverage, avg.count > 0 {
                        HStack {
                            Spacer()
                            Text("過去3ヶ月平均: ¥\(avg.average.formattedComma) (\(avg.count)件)")
                                .font(.caption)
                                .foregroundStyle(Palette.mutedForeground)
                        }
                    }
                    Picker("支払日", selection: $draft.payDay) {
                        ForEach(1...28, id: \.self) { d in
                            Text("\(d)日").tag(d)
                        }
                    }
                    Picker("必須/任意", selection: $draft.isRequired) {
                        Text("必須").tag(true)
                        Text("任意").tag(false)
                    }
                    Toggle("シナリオで有効", isOn: $draft.isEnabled)
                }

                Section("適用月") {
                    MonthSelector(months: $draft.months)
                        .padding(.vertical, 4)
                }

                if let error = errorMessage {
                    Section {
                        Text(error).font(.footnote).foregroundStyle(Palette.expense)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Palette.background)
            .navigationTitle(draft.itemID == nil ? "項目を追加" : "項目を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                        .fontWeight(.bold)
                        .tint(Palette.mutedForeground2)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { Task { await save() } }
                        .fontWeight(.bold)
                        .tint(Palette.primaryStrong)
                        .disabled(isSaving || draft.name.isEmpty)
                }
            }
            .task(id: "\(draft.name)-\(draft.category.rawValue)") {
                await loadAverage()
            }
        }
    }

    private func loadAverage() async {
        let trimmed = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard draft.category == .variable, !trimmed.isEmpty else {
            historyAverage = nil
            return
        }
        historyAverage = await store.fetchHistoryAverage(name: trimmed)
    }

    private func save() async {
        let trimmed = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "名称を入力してください"
            return
        }
        guard let amountInt = Int(draft.amount), amountInt >= 0 else {
            errorMessage = "金額は0以上の半角数字で入力してください"
            return
        }
        guard !draft.months.isEmpty else {
            errorMessage = "適用月を1つ以上選択してください"
            return
        }
        isSaving = true
        defer { isSaving = false }
        errorMessage = nil

        let input = ScenarioItemInput(
            scenario: store.id,
            name: trimmed,
            payDay: draft.payDay,
            method: nil,
            amount: amountInt,
            category: draft.category,
            isRequired: draft.isRequired,
            isEnabled: draft.isEnabled,
            months: draft.months.sorted()
        )
        do {
            try await store.saveItem(input, itemID: draft.itemID)
            Haptics.success()
            onSaved()
            dismiss()
        } catch let error as AppError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private extension Int {
    var formattedComma: String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
