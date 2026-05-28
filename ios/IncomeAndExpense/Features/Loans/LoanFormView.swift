import SwiftUI

struct LoanFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State var viewModel: LoanFormViewModel
    private let methodsStore = MethodsStore.shared
    let onSaved: () -> Void

    private static let yearRange: [Int] = {
        let current = Calendar.current.component(.year, from: Date())
        return Array((current - 5)...(current + 30))
    }()

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
                        ForEach(1...28, id: \.self) { day in
                            Text(verbatim: "\(day)日").tag(day)
                        }
                    }
                    Picker("状態", selection: $viewModel.state) {
                        ForEach(InexState.allCases) { state in
                            Text(state.label).tag(state)
                        }
                    }
                }

                Section("期間") {
                    HStack {
                        Text("開始")
                        Spacer()
                        Picker("開始年", selection: $viewModel.firstYear) {
                            ForEach(Self.yearRange, id: \.self) { y in
                                Text(verbatim: "\(y)年").tag(y)
                            }
                        }
                        .labelsHidden()
                        Picker("開始月", selection: $viewModel.firstMonth) {
                            ForEach(1...12, id: \.self) { m in
                                Text(verbatim: "\(m)月").tag(m)
                            }
                        }
                        .labelsHidden()
                    }
                    HStack {
                        Text("終了")
                        Spacer()
                        Picker("終了年", selection: $viewModel.lastYear) {
                            ForEach(Self.yearRange, id: \.self) { y in
                                Text(verbatim: "\(y)年").tag(y)
                            }
                        }
                        .labelsHidden()
                        Picker("終了月", selection: $viewModel.lastMonth) {
                            ForEach(1...12, id: \.self) { m in
                                Text(verbatim: "\(m)月").tag(m)
                            }
                        }
                        .labelsHidden()
                    }
                }

                Section("金額") {
                    TextField("初回", text: $viewModel.amountFirst)
                        .keyboardType(.numberPad)
                    TextField("2回目以降", text: $viewModel.amountFromSecond)
                        .keyboardType(.numberPad)
                }

                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(viewModel.isEdit ? "ローンを編集" : "新しいローン")
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
            }
        }
    }
}
