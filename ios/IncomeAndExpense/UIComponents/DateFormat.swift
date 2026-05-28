import Foundation

extension Date {
    /// 「5月28日」形式の日付表示。アプリ全体の支払日表示はこれに統一する。
    var japaneseMonthDay: String {
        let cal = Calendar.current
        let m = cal.component(.month, from: self)
        let d = cal.component(.day, from: self)
        return "\(m)月\(d)日"
    }
}
