import SwiftUI
import Charts

struct TrendChart: View {
    let months: [TrendMonth]

    var body: some View {
        Chart {
            ForEach(months, id: \.self) { m in
                BarMark(
                    x: .value("月", monthDate(m), unit: .month),
                    y: .value("円", m.income)
                )
                .foregroundStyle(by: .value("種別", "収入"))
                .position(by: .value("種別", "収入"))

                BarMark(
                    x: .value("月", monthDate(m), unit: .month),
                    y: .value("円", m.expense)
                )
                .foregroundStyle(by: .value("種別", "支出"))
                .position(by: .value("種別", "支出"))
            }
        }
        .chartForegroundStyleScale([
            "収入": Palette.income,
            "支出": Palette.expense,
        ])
        .chartLegend(position: .top, alignment: .trailing)
        .chartXAxis {
            // 12ヶ月分のラベルが重ならないよう2ヶ月おきに表示
            AxisMarks(values: .stride(by: .month, count: 2)) { value in
                AxisGridLine()
                AxisTick()
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(date, format: .dateTime.year(.twoDigits).month(.defaultDigits))
                            .font(.caption2)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel {
                    if let amount = value.as(Double.self) {
                        // 指数表記(4.0E6)ではなく「400万」のような短縮表記
                        Text(Int(amount).formatted(.number.notation(.compactName)))
                            .font(.caption2)
                    }
                }
            }
        }
    }

    private func monthDate(_ m: TrendMonth) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? .current
        return calendar.date(
            from: DateComponents(year: m.year, month: m.month)
        ) ?? Date()
    }
}
