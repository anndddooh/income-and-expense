import SwiftUI

struct ExpenseFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State var viewModel: ExpenseFormViewModel
    private let methodsStore = MethodsStore.shared
    private let templatesStore = TemplateExpensesStore.shared
    @State private var selectedTemplateID: Int?
    let onSaved: () -> Void

    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            Form {
                if !viewModel.isEdit, !templatesStore.templates.isEmpty {
                    Section("簡易入力") {
                        Picker("テンプレート", selection: $selectedTemplateID) {
                            Text("選択してください").tag(Int?.none)
                            ForEach(templatesStore.templates) { template in
                                Text(template.templateName).tag(Int?.some(template.id))
                            }
                        }
                        .onChange(of: selectedTemplateID) { _, newValue in
                            guard let id = newValue,
                                  let template = templatesStore.templates
                                    .first(where: { $0.id == id })
                            else { return }
                            viewModel.applyTemplate(template)
                            Haptics.tap()
                        }
                    }
                }

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
                    Picker("状態", selection: $viewModel.state) {
                        ForEach(InexState.allCases) { state in
                            Text(state.label).tag(state)
                        }
                    }
                }

                Section("メモ") {
                    TextField("メモ(任意)", text: $viewModel.memo, axis: .vertical)
                        .lineLimit(3...6)
                }

                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(viewModel.isEdit ? "支出を編集" : "新しい支出")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
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
                    .disabled(viewModel.isSaving)
                }
            }
            .task {
                await methodsStore.loadIfNeeded()
                await templatesStore.loadIfNeeded()
            }
        }
    }
}
