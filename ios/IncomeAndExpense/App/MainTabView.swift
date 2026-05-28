import SwiftUI

@MainActor
struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack { DashboardView() }
                .tabItem { Label("ホーム", systemImage: "house.fill") }

            NavigationStack { IncomeListView() }
                .tabItem { Label("収入", systemImage: "arrow.down.circle.fill") }

            NavigationStack { ExpenseListView() }
                .tabItem { Label("支出", systemImage: "arrow.up.circle.fill") }

            morePlaceholder()
                .tabItem { Label("その他", systemImage: "ellipsis.circle.fill") }
        }
    }

    private func placeholderTab(title: String, note: String) -> some View {
        NavigationStack {
            VStack(spacing: 12) {
                Text(title).font(.title)
                Text(note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    MonthPicker(store: MonthStore.shared)
                }
            }
        }
    }

    private func morePlaceholder() -> some View {
        NavigationStack {
            List {
                Section("家計") {
                    NavigationLink("ローン") { LoanListView() }
                    NavigationLink("残高") { BalanceView() }
                    NavigationLink("口座別必要額") { AccountRequireView() }
                    NavigationLink("支払方法別必要額") { MethodRequireView() }
                }
                Section("設定") {
                    NavigationLink("設定") { SettingsView() }
                }
                Section {
                    Button(role: .destructive) {
                        AuthStore.shared.logout()
                    } label: {
                        Label("ログアウト", systemImage: "arrow.right.square")
                    }
                }
            }
            .navigationTitle("その他")
        }
    }
}
