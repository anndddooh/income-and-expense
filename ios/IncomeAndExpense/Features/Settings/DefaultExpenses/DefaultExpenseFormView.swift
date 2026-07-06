import SwiftUI

struct DefaultExpenseFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State var viewModel: DefaultExpenseFormViewModel
    private let methodsStore = MethodsStore.shared
    let onSaved: () -> Void

    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            Form {
                Section {
                    TextField("名前", text: $viewModel.name)
                    Picker("支払方法", selection: $viewModel.methodID) {
                        Text("選択してください").tag(Int?.none)
                        ForEach(methodsStore.methods) { method in
                            Text(method.displayName).tag(Int?.some(method.id))
                        }
                    }
                    Picker("支払日", selection: $viewModel.payDay) {
                        ForEach(1...28, id: \.self) { d in
                            Text(verbatim: "\(d)日").tag(d)
                        }
                    }
                    TextField("金額", text: $viewModel.amount)
                        .keyboardType(.numberPad)
                    StatePickerRow(state: $viewModel.state)
                    Picker("費目区分", selection: $viewModel.category) {
                        ForEach(ExpenseCategory.allCases) { cat in
                            Text(cat.label).tag(cat)
                        }
                    }
                    Toggle("必須の支出", isOn: $viewModel.isRequired)
                }

                Section("対象月") {
                    MonthSelector(months: $viewModel.months)
                        .padding(.vertical, 4)
                }

                if let error = viewModel.errorMessage {
                    Section {
                        Text(error).font(.footnote).foregroundStyle(Palette.expense)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Palette.background)
            .navigationTitle(viewModel.isEdit ? "デフォルト支出を編集" : "新しいデフォルト支出")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                        .fontWeight(.bold)
                        .tint(Palette.mutedForeground2)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        Task {
                            if await viewModel.save() {
                                Haptics.success()
                                onSaved()
                                dismiss()
                            }
                        }
                    }
                    .fontWeight(.bold)
                    .tint(Palette.primaryStrong)
                    .disabled(viewModel.isSaving)
                }
            }
            .task {
                await methodsStore.loadIfNeeded()
            }
        }
    }
}
