import Foundation

extension Int {
    /// 「¥1,234」形式の文字列。アプリ全体の金額表示はこれに統一する。
    var yenString: String {
        "¥\(formatted(.number.grouping(.automatic)))"
    }
}

extension Optional where Wrapped == Int {
    /// 値が nil のときは「-」を返す金額表示。
    var yenStringOrDash: String {
        self?.yenString ?? "-"
    }
}
