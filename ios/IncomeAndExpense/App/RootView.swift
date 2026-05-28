import SwiftUI

struct RootView: View {
    private let authStore = AuthStore.shared

    var body: some View {
        Group {
            if authStore.isLoggedIn {
                MainTabView()
            } else {
                LoginView()
            }
        }
    }
}

#Preview {
    RootView()
}
