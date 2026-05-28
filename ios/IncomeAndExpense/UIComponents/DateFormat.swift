import Foundation

extension Date {
    /// 「5月28日」形式の日付表示。アプリ全体の支払日表示はこれに統一する。
    var japaneseMonthDay: String {
        let cal = Calendar.current
        let m = cal.component(.month, from: self)
        let d = cal.component(.day, from: self)
        return "\(m)月\(d)日"
    }

    /// 「2026年5月28日」形式の日付表示。フォーム入力欄など年も必要な箇所で使う。
    var japaneseYearMonthDay: String {
        let cal = Calendar.current
        let y = cal.component(.year, from: self)
        let m = cal.component(.month, from: self)
        let d = cal.component(.day, from: self)
        return "\(y)年\(m)月\(d)日"
    }
}
