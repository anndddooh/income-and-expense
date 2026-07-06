import SwiftUI

struct IncomeFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State var viewModel: IncomeFormViewModel
    private let methodsStore = MethodsStore.shared
    let onSaved: () -> Void

    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            Form {
                Section {
                    TextField("名前", text: $viewModel.name)
                    JapaneseDatePicker(
                        title: "支払日",
                        selection: $viewModel.payDate
                    )
                    Picker("支払方法", selection: $viewModel.methodID) {
                        Text("選択してください").tag(Int?.none)
                        ForEach(methodsStore.methods) { method in
                            Text(method.displayName).tag(Int?.some(method.id))
                        }
                    }
                    TextField("金額", text: $viewModel.amount)
                        .keyboardType(.numberPad)
                    StatePickerRow(state: $viewModel.state)
                }

                Section("メモ") {
                    TextField("メモ(任意)", text: $viewModel.memo, axis: .vertical)
                        .lineLimit(3...6)
                }

                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(Palette.expense)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Palette.background)
            .navigationTitle(viewModel.isEdit ? "収入を編集" : "新しい収入")
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
