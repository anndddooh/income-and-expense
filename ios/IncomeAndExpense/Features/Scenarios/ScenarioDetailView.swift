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
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                modeCard
                summaryCard
                if let s = store.summary, (s.fixed + s.variable + s.oneTime) > 0 {
                    chartCard(s)
                }
                itemsCard

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
        .navigationTitle(store.scenario?.name ?? initialName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    editing = ScenarioItemDraft.empty()
                } label: {
                    Image(systemName: "plus")
                }
                .tint(Palette.primaryStrong)
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

    private var modeCard: some View {
        VStack(spacing: 12) {
            Picker("モード", selection: $mode) {
                Text("月次").tag("monthly")
                Text("年次").tag("yearly")
            }
            .pickerStyle(.segmented)
            if mode == "monthly" {
                HStack {
                    Text("対象月")
                        .font(.yutori(14))
                        .foregroundStyle(Palette.foreground)
                    Spacer()
                    Picker("対象月", selection: $targetMonth) {
                        ForEach(1...12, id: \.self) { m in
                            Text("\(m)月").tag(m)
                        }
                    }
                    .labelsHidden()
                    .tint(Palette.primaryStrong)
                }
            }
        }
        .padding(16)
        .yutoriCard()
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 7) {
            GroupCaption("集計")
            VStack(spacing: 10) {
                if let s = store.summary {
                    summaryRow("収入", s.income, bold: true)
                    summaryRow("固定費", s.fixed)
                    summaryRow("変動費", s.variable)
                    summaryRow("単発", s.oneTime)
                    summaryRow("合計支出", s.totalExpense, bold: true)
                    summaryRow(
                        "収支", s.balance, bold: true,
                        tint: s.balance < 0 ? Palette.expense : Palette.income
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
                                    .font(.yutori(12.5, weight: .bold))
                                    .foregroundStyle(Palette.primaryStrong)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } else {
                    Text("集計中...")
                        .font(.yutori(12.5))
                        .foregroundStyle(Palette.mutedForeground)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(16)
            .yutoriCard()
        }
    }

    private func chartCard(_ s: ScenarioSummary) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            GroupCaption("区分比率")
            Chart {
                if s.fixed > 0 {
                    SectorMark(
                        angle: .value("金額", s.fixed),
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .foregroundStyle(Palette.stateDecided)
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
                    .foregroundStyle(Palette.accent)
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
                    .foregroundStyle(Palette.stateDone)
                    .annotation(position: .overlay) {
                        Text("単発").font(.caption2)
                    }
                }
            }
            .frame(height: 200)
            .padding(16)
            .yutoriCard()
        }
    }

    private var itemsCard: some View {
        VStack(alignment: .leading, spacing: 7) {
            GroupCaption("項目 (\(store.scenario?.itemCount ?? 0))")
            if let scenario = store.scenario, !scenario.items.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(scenario.items.enumerated()), id: \.element.id) { index, item in
                        itemRow(item)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .contextMenu {
                                Button(role: .destructive) {
                                    Task {
                                        try? await store.deleteItem(itemID: item.id)
                                        await load()
                                    }
                                } label: {
                                    Label("削除", systemImage: "trash")
                                }
                            }
                        if index < scenario.items.count - 1 {
                            Rectangle()
                                .fill(Palette.rowSeparator)
                                .frame(height: 1)
                        }
                    }
                }
                .yutoriCard()
            } else {
                VStack {
                    PlaceholderRow(kind: .empty(icon: "flask", message: "項目がありません"))
                }
                .frame(maxWidth: .infinity)
                .yutoriCard()
            }
        }
    }

    private func itemRow(_ item: ScenarioItem) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Button {
                Task {
                    try? await store.toggleItem(itemID: item.id, isEnabled: !item.isEnabled)
                    await load()
                }
            } label: {
                Image(systemName: item.isEnabled ? "checkmark.square.fill" : "square")
                    .font(.system(size: 18))
                    .foregroundStyle(item.isEnabled ? Palette.primaryStrong : Palette.mutedForeground)
            }
            .buttonStyle(.plain)

            Button {
                editing = ScenarioItemDraft.from(item: item)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(item.name)
                            .font(.yutori(15, weight: .bold))
                            .foregroundStyle(item.isEnabled ? Palette.foreground : Palette.mutedForeground)
                        attributeBadge(item.categoryLabel, tint: categoryTint(item.category))
                        attributeBadge(
                            item.isRequired ? "必須" : "任意",
                            tint: item.isRequired ? Palette.primaryStrong : Palette.mutedForeground
                        )
                        Spacer()
                        Text(item.amount.yenString)
                            .font(.yutori(12.5, weight: .bold))
                            .monospacedDigit()
                            .foregroundStyle(Palette.foreground)
                    }
                    Text(monthsLabel(item.months))
                        .font(.yutori(11))
                        .foregroundStyle(Palette.mutedForeground)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
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
        HStack {
            Text(label)
                .font(.yutori(14, weight: bold ? .bold : .regular))
                .foregroundStyle(Palette.foreground)
            Spacer()
            Text(value.yenString)
                .font(.yutori(14, weight: bold ? .bold : .regular))
                .monospacedDigit()
                .foregroundStyle(tint ?? Palette.foreground)
        }
    }

    private func attributeBadge(_ text: String, tint: Color) -> some View {
        Text(text)
            .font(.yutori(11, weight: .bold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(tint.opacity(0.15), in: Capsule())
            .foregroundStyle(tint)
    }

    private func categoryTint(_ category: ExpenseCategory) -> Color {
        switch category {
        case .fixed: return Palette.stateDecided
        case .variable: return Palette.accent
        case .oneTime: return Palette.stateDone
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
