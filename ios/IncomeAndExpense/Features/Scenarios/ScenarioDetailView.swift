import SwiftUI
import Charts

struct ScenarioDetailView: View {
    @State private var store: ScenarioDetailStore
    @State private var mode: String = "monthly"
    @State private var targetMonth: Int = Calendar.current.component(.month, from: Date())
    @State private var editing: ScenarioItemDraft? = nil
    let initialName: String

    init(scenarioID: Int, initialName: String) {
        _store = State(initialValue: ScenarioDetailStore(id: scenarioID))
        self.initialName = initialName
    }

    var body: some View {
        List {
            modeSection
            summarySection
            if let s = store.summary, (s.fixed + s.variable + s.oneTime) > 0 {
                chartSection(s)
            }
            itemsSection
            if let error = store.errorMessage {
                Section {
                    Text(error).font(.footnote).foregroundStyle(.red)
                }
            }
        }
        .navigationTitle(store.scenario?.name ?? initialName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    editing = ScenarioItemDraft.empty()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .task { await load() }
        .refreshable { await load() }
        .sheet(item: $editing) { draft in
            ScenarioItemEditView(
                draft: draft,
                store: store,
                onSaved: { Task { await load() } }
            )
        }
        .onChange(of: mode) { _, _ in Task { await loadSummary() } }
        .onChange(of: targetMonth) { _, _ in Task { await loadSummary() } }
    }

    private func load() async {
        await store.fetch()
        await loadSummary()
    }

    private func loadSummary() async {
        await store.fetchSummary(
            mode: mode,
            month: mode == "monthly" ? targetMonth : nil
        )
    }

    private var modeSection: some View {
        Section {
            Picker("モード", selection: $mode) {
                Text("月次").tag("monthly")
                Text("年次").tag("yearly")
            }
            .pickerStyle(.segmented)
            if mode == "monthly" {
                Picker("対象月", selection: $targetMonth) {
                    ForEach(1...12, id: \.self) { m in
                        Text("\(m)月").tag(m)
                    }
                }
            }
        }
    }

    private var summarySection: some View {
        Section("集計") {
            if let s = store.summary {
                summaryRow("収入", s.income, bold: true)
                summaryRow("固定費", s.fixed)
                summaryRow("変動費", s.variable)
                summaryRow("単発", s.oneTime)
                summaryRow("合計支出", s.totalExpense, bold: true)
                summaryRow(
                    "収支", s.balance, bold: true,
                    tint: s.balance < 0 ? .red : .green
                )
                summaryRow("必須支出計", s.required)
                summaryRow("任意支出計", s.optional)

                if let scenario = store.scenario {
                    let optionalEnabled = scenario.items
                        .filter { !$0.isRequired && $0.isEnabled }
                        .reduce(0) { $0 + $1.amount }
                    if optionalEnabled > 0 {
                        Button {
                            Task { await turnAllOptionalOff() }
                        } label: {
                            Text("任意支出を全てオフ (¥\(optionalEnabled.formattedComma) 浮きます)")
                                .font(.caption)
                        }
                    }
                }
            } else {
                Text("集計中...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func chartSection(_ s: ScenarioSummary) -> some View {
        Section("区分比率") {
            Chart {
                if s.fixed > 0 {
                    SectorMark(
                        angle: .value("金額", s.fixed),
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .foregroundStyle(.blue)
                    .annotation(position: .overlay) {
                        Text("固定").font(.caption2)
                    }
                }
                if s.variable > 0 {
                    SectorMark(
                        angle: .value("金額", s.variable),
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .foregroundStyle(.orange)
                    .annotation(position: .overlay) {
                        Text("変動").font(.caption2)
                    }
                }
                if s.oneTime > 0 {
                    SectorMark(
                        angle: .value("金額", s.oneTime),
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .foregroundStyle(.purple)
                    .annotation(position: .overlay) {
                        Text("単発").font(.caption2)
                    }
                }
            }
            .frame(height: 200)
        }
    }

    private var itemsSection: some View {
        Section("項目 (\(store.scenario?.itemCount ?? 0))") {
            if let scenario = store.scenario {
                ForEach(scenario.items) { item in
                    itemRow(item)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                Task {
                                    try? await store.deleteItem(itemID: item.id)
                                    await load()
                                }
                            } label: {
                                Label("削除", systemImage: "trash")
                            }
                        }
                }
            }
        }
    }

    private func itemRow(_ item: ScenarioItem) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Button {
                Task {
                    try? await store.toggleItem(itemID: item.id, isEnabled: !item.isEnabled)
                    await load()
                }
            } label: {
                Image(systemName: item.isEnabled ? "checkmark.square.fill" : "square")
                    .foregroundStyle(item.isEnabled ? Color.accentColor : Color.secondary)
            }
            .buttonStyle(.plain)

            Button {
                editing = ScenarioItemDraft.from(item: item)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(item.name)
                            .font(.body)
                            .foregroundStyle(item.isEnabled ? .primary : .secondary)
                        attributeBadge(item.categoryLabel, tint: categoryTint(item.category))
                        attributeBadge(
                            item.isRequired ? "必須" : "任意",
                            tint: item.isRequired ? .accentColor : .secondary
                        )
                        Spacer()
                        Text(item.amount.yenString)
                            .font(.caption.monospacedDigit())
                    }
                    Text(monthsLabel(item.months))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
        }
        .opacity(item.isEnabled ? 1.0 : 0.5)
    }

    private func summaryRow(
        _ label: String,
        _ value: Int,
        bold: Bool = false,
        tint: Color? = nil
    ) -> some View {
        let font: Font = bold ? Font.body.weight(.semibold) : Font.body
        return HStack {
            Text(label).font(font)
            Spacer()
            Text(value.yenString)
                .font(font.monospacedDigit())
                .foregroundStyle(tint ?? Color.primary)
        }
    }

    private func attributeBadge(_ text: String, tint: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(tint.opacity(0.15), in: Capsule())
            .foregroundStyle(tint)
    }

    private func categoryTint(_ category: ExpenseCategory) -> Color {
        switch category {
        case .fixed: return .blue
        case .variable: return .orange
        case .oneTime: return .purple
        }
    }

    private func monthsLabel(_ months: [Int]) -> String {
        if months.count == 12 { return "毎月" }
        return months.map { "\($0)月" }.joined(separator: " ")
    }

    private func turnAllOptionalOff() async {
        guard let scenario = store.scenario else { return }
        for item in scenario.items where !item.isRequired && item.isEnabled {
            try? await store.toggleItem(itemID: item.id, isEnabled: false)
        }
        await load()
        Haptics.success()
    }
}

private extension Int {
    var formattedComma: String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
