import SwiftUI

@MainActor
struct MainTabView: View {
    init() {
        Self.configureBarAppearance()
    }

    var body: some View {
        TabView {
            NavigationStack { DashboardView() }
                .tabItem { Label("ホーム", systemImage: "house.fill") }

            NavigationStack { IncomeListView() }
                .tabItem { Label("収入", systemImage: "arrow.down.circle.fill") }

            NavigationStack { ExpenseListView() }
                .tabItem { Label("支出", systemImage: "arrow.up.circle.fill") }

            NavigationStack { BalanceView() }
                .tabItem { Label("残高", systemImage: "wallet.pass.fill") }

            NavigationStack { MoreView() }
                .tabItem { Label("その他", systemImage: "ellipsis.circle.fill") }
        }
        .tint(Palette.primaryStrong)
    }

    /// ナビバー・タブバーの背景を「ゆとり」テーマに合わせる。
    private static func configureBarAppearance() {
        let card = UIColor { $0.userInterfaceStyle == .dark
            ? UIColor(red: 0x24 / 255, green: 0x20 / 255, blue: 0x1A / 255, alpha: 1)
            : UIColor(red: 0xFF / 255, green: 0xFC / 255, blue: 0xF4 / 255, alpha: 1)
        }

        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = card
        nav.shadowColor = UIColor { $0.userInterfaceStyle == .dark
            ? UIColor(white: 1, alpha: 0.08)
            : UIColor(red: 0xEE / 255, green: 0xE3 / 255, blue: 0xCA / 255, alpha: 1)
        }
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav

        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = card
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab
    }
}

/// 「その他」タブ。家計・分析・設定のグループとログアウトを持つ。
/// 「残高」はタブに昇格したためこのメニューからは除外する。
private struct MoreView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ScreenHeading("その他")

                moreGroup(header: "家計") {
                    moreRow("ローン") { LoanListView() }
                    moreRow("口座別必要額") { AccountRequireView() }
                    moreRow("支払方法別必要額") { MethodRequireView() }
                }

                moreGroup(header: "分析") {
                    moreRow("シミュレーター") { ScenarioListView() }
                }

                moreGroup(header: "設定") {
                    moreRow("設定") { SettingsView() }
                }

                VStack(spacing: 0) {
                    Button {
                        AuthStore.shared.logout()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("ログアウト")
                            Spacer()
                        }
                        .font(.yutori(15, weight: .bold))
                        .foregroundStyle(Palette.expense)
                        .frame(minHeight: 48)
                        .padding(.horizontal, 16)
                    }
                    .buttonStyle(.plain)
                }
                .yutoriCard()
            }
            .padding(16)
        }
        .background(Palette.background)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func moreGroup<Content: View>(
        header: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            GroupCaption(header)
            VStack(spacing: 0) {
                content()
            }
            .yutoriCard()
        }
    }

    private func moreRow<Destination: View>(
        _ title: String,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        NavigationLink(destination: destination()) {
            HStack {
                Text(title)
                    .font(.yutori(15, weight: .bold))
                    .foregroundStyle(Palette.foreground)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Palette.accent)
            }
            .frame(minHeight: 48)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Palette.rowSeparator)
                .frame(height: 1)
                .padding(.leading, 16)
        }
    }
}
