import SwiftUI

struct SettingsView: View {
    var body: some View {
        List {
            Section("テンプレート") {
                NavigationLink {
                    DefaultIncomeListView()
                } label: {
                    Label("デフォルト収入", systemImage: "arrow.down.circle")
                }
                NavigationLink {
                    DefaultExpenseListView()
                } label: {
                    Label("デフォルト支出", systemImage: "arrow.up.circle")
                }
            }
        }
        .navigationTitle("設定")
    }
}
