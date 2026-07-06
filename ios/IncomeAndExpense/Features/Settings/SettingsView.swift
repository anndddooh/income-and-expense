import SwiftUI

struct SettingsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ScreenHeading("設定")

                VStack(alignment: .leading, spacing: 7) {
                    GroupCaption("テンプレート")
                    VStack(spacing: 0) {
                        NavigationLink { DefaultIncomeListView() } label: {
                            settingRow(
                                title: "デフォルト収入",
                                subtitle: "毎月の定期収入テンプレート",
                                icon: "banknote.fill",
                                tint: Palette.income
                            )
                        }
                        .buttonStyle(.plain)
                        .overlay(alignment: .bottom) {
                            Rectangle().fill(Palette.rowSeparator).frame(height: 1)
                                .padding(.leading, 16)
                        }

                        NavigationLink { DefaultExpenseListView() } label: {
                            settingRow(
                                title: "デフォルト支出",
                                subtitle: "毎月の定期支出テンプレート",
                                icon: "list.bullet.rectangle.fill",
                                tint: Palette.primary
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .yutoriCard()
                }
            }
            .padding(16)
        }
        .background(Palette.background)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func settingRow(title: String, subtitle: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 40, height: 40)
                .background(tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.yutori(15, weight: .bold))
                    .foregroundStyle(Palette.foreground)
                Text(subtitle)
                    .font(.yutori(11.5))
                    .foregroundStyle(Palette.mutedForeground)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Palette.accent)
        }
        .frame(minHeight: 60)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }
}
