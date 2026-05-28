import Foundation
import Observation

@Observable
final class MethodsStore {
    static let shared = MethodsStore()

    var methods: [Method] = []
    var isLoading: Bool = false

    private init() {}

    func loadIfNeeded() async {
        guard methods.isEmpty, !isLoading else { return }
        await reload()
    }

    func reload() async {
        isLoading = true
        defer { isLoading = false }
        do {
            methods = try await APIClient.shared.request(
                APIEndpoint(path: "/methods/")
            )
        } catch {
            // 取得失敗時はサイレント、UI側で再ロード可
        }
    }
}
