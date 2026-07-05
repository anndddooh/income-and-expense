import SwiftUI

/// アプリ共通の配色（「ゆとり」テーマ: 生成りベース × ハニーイエロー）。
/// ライトモードが確定仕様。ダークモードは未設計のため近似値で adaptive 構造のみ維持する。
enum Palette {
    // MARK: - サーフェス / テキスト

    /// ページ背景（生成り） #faf5ea
    static let background = token(light: 0xFAF5EA, dark: 0x1A1712)
    /// カード・ナビバー背景 #fffcf4
    static let card = token(light: 0xFFFCF4, dark: 0x24201A)
    /// カード枠線 #eee3ca
    static let cardBorder = token(light: 0xEEE3CA, dark: 0x3A342A)
    /// 入力欄枠線 #eadfc4
    static let inputBorder = token(light: 0xEADFC4, dark: 0x3A342A)
    /// リスト行区切り #f5eeda
    static let rowSeparator = token(light: 0xF5EEDA, dark: 0x2E2A22)
    /// 本文テキスト #3d362a
    static let foreground = token(light: 0x3D362A, dark: 0xF0E9DA)
    /// 補助テキスト #8f8468
    static let mutedForeground = token(light: 0x8F8468, dark: 0xA89E86)
    /// ナビ非アクティブ等 #6d6353
    static let mutedForeground2 = token(light: 0x6D6353, dark: 0xCFC6B3)
    /// プレースホルダー #b7ac97
    static let placeholder = token(light: 0xB7AC97, dark: 0x7A7360)

    // MARK: - ハニー系アクセント

    /// 主ボタン背景（honey） #b3801f
    static let primary = token(light: 0xB3801F, dark: 0xD1A13C)
    /// アクティブナビ文字・リンク・iOSタブtint #9a6b1f
    static let primaryStrong = token(light: 0x9A6B1F, dark: 0xE0B458)
    /// アクティブナビ背景 rgba(209,161,60,0.18)
    static let primarySoft = Color(red: 209 / 255, green: 161 / 255, blue: 60 / 255).opacity(0.18)
    /// アウトライン枠・chevron・チャート支出バー（honey-light） #d1a13c
    static let accent = token(light: 0xD1A13C, dark: 0xD1A13C)
    /// セグメントコントロールのトラック #f1e7cd
    static let segmentTrack = token(light: 0xF1E7CD, dark: 0x35301F)

    // MARK: - セマンティック

    /// 収入 / プラス収支 / チャート収入バー #6e9a54
    static let income = token(light: 0x6E9A54, dark: 0x8FBF72)
    /// 支出 / 不足額 / 削除 / ログアウト #b3584c
    static let expense = token(light: 0xB3584C, dark: 0xD68075)
    /// 旧 API 互換: 未確定など中間状態（= state-未定）
    static let pending = token(light: 0xB08430, dark: 0xC79A4E)

    // MARK: - 状態カラー

    /// state-未定 #b08430
    static let stateUndecided = token(light: 0xB08430, dark: 0xC79A4E)
    /// state-確定 #64798f
    static let stateDecided = token(light: 0x64798F, dark: 0x8B9DB2)
    /// state-完了 #52796b
    static let stateDone = token(light: 0x52796B, dark: 0x7BA695)

    /// 状態バッジ/チップの前景色。
    static func stateColor(_ state: InexState) -> Color {
        switch state {
        case .undecided: return stateUndecided
        case .decided: return stateDecided
        case .done: return stateDone
        }
    }

    /// 状態バッジ/チップの背景色（前景色を ~16% 不透明度）。
    static func stateBackground(_ state: InexState) -> Color {
        stateColor(state).opacity(0.16)
    }

    /// 金額の正負に応じた色。0 は foreground。
    static func amount(_ value: Int) -> Color {
        if value > 0 { return income }
        if value < 0 { return expense }
        return foreground
    }

    // MARK: - Helpers

    private static func token(light: UInt, dark: UInt) -> Color {
        Color(uiColor: UIColor { traits in
            UIColor(rgb: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

private extension UIColor {
    convenience init(rgb: UInt) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: 1
        )
    }
}

// MARK: - 共通タイポグラフィ

extension Font {
    /// M PLUS Rounded 1c 相当（未バンドルのためシステム丸ゴを代替使用）。
    static func yutori(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

// MARK: - 共通コンポーネント

/// 各画面のスクロール先頭に置く大見出し（21px/800）。
struct ScreenHeading: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.yutori(21, weight: .heavy))
            .foregroundStyle(Palette.foreground)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// グループカードの小見出し（12.5px/700, muted）。
struct GroupCaption: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.yutori(12.5, weight: .bold))
            .foregroundStyle(Palette.mutedForeground)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 6)
    }
}

extension View {
    /// 「ゆとり」カード外観（card 背景 + border 枠、影なし、角丸 20/16）。
    func yutoriCard(radius: CGFloat = 20) -> some View {
        self
            .background(Palette.card, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(Palette.cardBorder, lineWidth: 1)
            )
    }
}

/// 全幅 48px の pill ボタン（primary 塗り or outline）。
struct YutoriPillButton: View {
    enum Kind { case primary, outline }
    let title: String
    var kind: Kind = .primary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.yutori(15, weight: .bold))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .foregroundStyle(kind == .primary ? Palette.card : Palette.primaryStrong)
                .background(
                    kind == .primary ? Palette.primary : Palette.card,
                    in: Capsule()
                )
                .overlay {
                    if kind == .outline {
                        Capsule().stroke(Palette.accent, lineWidth: 1.5)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}
