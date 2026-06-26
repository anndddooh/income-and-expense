import SwiftUI

struct ScenarioListView: View {
    @State private var store = ScenarioStore()
    @State private var showingNewForm = false
    @State private var newName: String = ""
    @State private var newNote: String = ""
    @State private var copyFromDefaults: Bool = true
    @State private var isCreating: Bool = false
    @State private var navigatingTo: Scenario? = nil

    var body: some View {
        List {
            if store.items.isEmpty {
                PlaceholderRow(kind: store.isLoading
                    ? .loading
                    : .empty(icon: "flask", message: "シナリオがありません"))
            }
            ForEach(store.items) { item in
                NavigationLink {
                    ScenarioDetailView(scenarioID: item.id, initialName: item.name)
                } label: {
                    row(item)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        Task { try? await store.delete(id: item.id) }
                    } label: {
                        Label("削除", systemImage: "trash")
                    }
                }
            }
            if let error = store.errorMessage {
                Section {
                    Text(error).font(.footnote).foregroundStyle(.red)
                }
            }
        }
        .refreshable { await store.fetch() }
        .task { await store.fetch() }
        .navigationTitle("シミュレーター")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingNewForm = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showingNewForm) {
            newScenarioSheet
        }
    }

    private func row(_ item: Scenario) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.name).font(.body)
            if !item.note.isEmpty {
                Text(item.note).font(.caption).foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Text(verbatim: "\(item.itemCount)項目 · 更新 \(item.updatedAt.prefix(10))")
                .font(.caption2).foregroundStyle(.secondary)
        }
    }

    private var newScenarioSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("名称", text: $newName)
                    TextField("備考", text: $newNote, axis: .vertical)
                        .lineLimit(2...4)
                }
                Section {
                    Toggle("現在のデフォルト支出をコピー", isOn: $copyFromDefaults)
                }
            }
            .navigationTitle("新しいシナリオ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { resetNewForm() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("作成") {
                        Task { await performCreate() }
                    }
                    .disabled(
                        newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        || isCreating
                    )
                }
            }
        }
    }

    private func resetNewForm() {
        newName = ""
        newNote = ""
        copyFromDefaults = true
        showingNewForm = false
    }

    private func performCreate() async {
        isCreating = true
        defer { isCreating = false }
        do {
            let created = try await store.create(
                ScenarioInput(
                    name: newName.trimmingCharacters(in: .whitespacesAndNewlines),
                    note: newNote
                )
            )
            if copyFromDefaults {
                _ = try? await store.copyFromDefaults(id: created.id)
            }
            await store.fetch()
            resetNewForm()
            Haptics.success()
        } catch {
            store.errorMessage = (error as? AppError)?.errorDescription
                ?? error.localizedDescription
        }
    }
}
