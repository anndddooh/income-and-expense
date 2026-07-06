import SwiftUI

struct ScenarioListView: View {
    @State private var store = ScenarioStore()
    @State private var showingNewForm = false
    @State private var newName: String = ""
    @State private var newNote: String = ""
    @State private var copyFromDefaults: Bool = true
    @State private var isCreating: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    ScreenHeading("シミュレーター")
                    Text("収支シナリオを作って、支出の増減を試算できます。")
                        .font(.yutori(12.5))
                        .foregroundStyle(Palette.mutedForeground)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 4)

                listCard

                YutoriPillButton(title: "＋ 新しいシナリオ") { showingNewForm = true }

                if let error = store.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(Palette.expense)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(16)
        }
        .background(Palette.background)
        .refreshable { await store.fetch() }
        .task { await store.fetch() }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingNewForm = true } label: { Image(systemName: "plus") }
                    .tint(Palette.primaryStrong)
            }
        }
        .sheet(isPresented: $showingNewForm) {
            newScenarioSheet
        }
    }

    @ViewBuilder
    private var listCard: some View {
        if store.items.isEmpty {
            VStack {
                PlaceholderRow(kind: store.isLoading
                    ? .loading
                    : .empty(icon: "flask", message: "シナリオがありません"))
            }
            .frame(maxWidth: .infinity)
            .yutoriCard()
        } else {
            VStack(spacing: 0) {
                ForEach(Array(store.items.enumerated()), id: \.element.id) { index, item in
                    NavigationLink {
                        ScenarioDetailView(scenarioID: item.id, initialName: item.name)
                    } label: {
                        row(item)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            Task { try? await store.delete(id: item.id) }
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                    }
                    if index < store.items.count - 1 {
                        Rectangle()
                            .fill(Palette.rowSeparator)
                            .frame(height: 1)
                    }
                }
            }
            .yutoriCard()
        }
    }

    private func row(_ item: Scenario) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.yutori(15, weight: .bold))
                    .foregroundStyle(Palette.foreground)
                if !item.note.isEmpty {
                    Text(item.note)
                        .font(.yutori(11.5))
                        .foregroundStyle(Palette.mutedForeground)
                        .lineLimit(2)
                }
                Text(verbatim: "\(item.itemCount)項目 · 更新 \(item.updatedAt.prefix(10))")
                    .font(.yutori(11))
                    .foregroundStyle(Palette.mutedForeground)
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Palette.accent)
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
            .scrollContentBackground(.hidden)
            .background(Palette.background)
            .navigationTitle("新しいシナリオ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { resetNewForm() }
                        .fontWeight(.bold)
                        .tint(Palette.mutedForeground2)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("作成") {
                        Task { await performCreate() }
                    }
                    .fontWeight(.bold)
                    .tint(Palette.primaryStrong)
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
