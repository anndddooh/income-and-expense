import SwiftUI

/// 1〜12月を多選択する 4×3 のグリッド。デフォルト収入/支出フォームで使用。
struct MonthSelector: View {
    @Binding var months: [Int]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(1...12, id: \.self) { month in
                Button {
                    toggle(month)
                } label: {
                    Text(verbatim: "\(month)月")
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .background(
                            months.contains(month) ? Color.accentColor : Color.gray.opacity(0.15),
                            in: RoundedRectangle(cornerRadius: 8)
                        )
                        .foregroundStyle(months.contains(month) ? Color.white : Color.primary)
                        .font(.callout)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func toggle(_ month: Int) {
        if let index = months.firstIndex(of: month) {
            months.remove(at: index)
        } else {
            months.append(month)
            months.sort()
        }
    }
}
