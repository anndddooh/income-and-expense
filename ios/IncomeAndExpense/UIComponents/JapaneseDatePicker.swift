import SwiftUI

/// 「2026年5月28日」形式で日付を表示し、タップで展開するDatePicker。
/// SwiftUI標準のcompact DatePickerはロケール依存で表記がスラッシュ区切り
/// になるため、アプリ全体の日本語表記に合わせるために自作している。
struct JapaneseDatePicker: View {
    let title: String
    @Binding var selection: Date
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation { isExpanded.toggle() }
            } label: {
                HStack {
                    Text(title)
                        .foregroundStyle(.primary)
                    Spacer()
                    Text(verbatim: selection.japaneseYearMonthDay)
                        .foregroundStyle(isExpanded ? Color.accentColor : .primary)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .background(
                            Color(.tertiarySystemFill),
                            in: RoundedRectangle(cornerRadius: 7)
                        )
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                DatePicker(
                    "",
                    selection: $selection,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
                .environment(\.locale, Locale(identifier: "ja_JP"))
            }
        }
    }
}
