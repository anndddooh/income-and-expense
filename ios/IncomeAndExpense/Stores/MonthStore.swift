import Foundation
import Observation

@Observable
final class MonthStore {
    static let shared = MonthStore()

    var year: Int
    var month: Int

    private init() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? .current
        let comps = calendar.dateComponents([.year, .month], from: Date())
        self.year = comps.year ?? 2026
        self.month = comps.month ?? 1
    }

    func goToPreviousMonth() {
        if month == 1 {
            month = 12
            year -= 1
        } else {
            month -= 1
        }
    }

    func goToNextMonth() {
        if month == 12 {
            month = 1
            year += 1
        } else {
            month += 1
        }
    }

    func resetToCurrent() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? .current
        let comps = calendar.dateComponents([.year, .month], from: Date())
        year = comps.year ?? year
        month = comps.month ?? month
    }

    /// 表示中の年月が「現在月以降」かどうか。
    /// デフォルト適用は過去月で実行できないので、メニュー項目の有効化判定等に使用。
    var isCurrentOrFutureMonth: Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? .current
        let comps = calendar.dateComponents([.year, .month], from: Date())
        guard let currentYear = comps.year, let currentMonth = comps.month else {
            return true
        }
        if year > currentYear { return true }
        if year < currentYear { return false }
        return month >= currentMonth
    }
}
