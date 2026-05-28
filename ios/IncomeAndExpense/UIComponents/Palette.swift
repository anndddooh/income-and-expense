import SwiftUI

/// アプリ共通の配色。
/// 収支の正負を一目で示すための **彩度を抑えた** セマンティックカラー。
/// 数値や小さなバッジにのみ使い、面積広く塗らないこと。
enum Palette {
    /// 収入 / プラス。落ち着いたセージグリーン。
    static let income = adaptive(
        light: (0.16, 0.46, 0.38),
        dark: (0.44, 0.74, 0.62)
    )

    /// 支出 / マイナス / 不足。彩度を抑えたテラコッタレッド。
    static let expense = adaptive(
        light: (0.70, 0.32, 0.29),
        dark: (0.88, 0.52, 0.48)
    )

    /// 未確定など、注意を促す中間状態。くすんだアンバー。
    static let pending = adaptive(
        light: (0.65, 0.47, 0.16),
        dark: (0.85, 0.69, 0.40)
    )

    /// 金額の正負に応じた色。0 は primary(モノクロ)。
    static func amount(_ value: Int) -> Color {
        if value > 0 { return income }
        if value < 0 { return expense }
        return .primary
    }

    private static func adaptive(
        light: (CGFloat, CGFloat, CGFloat),
        dark: (CGFloat, CGFloat, CGFloat)
    ) -> Color {
        Color(uiColor: UIColor { traits in
            let c = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: c.0, green: c.1, blue: c.2, alpha: 1)
        })
    }
}
