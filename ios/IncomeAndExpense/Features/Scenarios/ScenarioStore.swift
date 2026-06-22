import Foundation
import Observation

@Observable
final class ScenarioStore {
    var items: [Scenario] = []
    var isLoading: Bool = false
    var errorMessage: String? = nil

    func fetch() async {
        isLoading = true
        defer { isLoading = false }
        do {
            items = try await APIClient.shared.request(
                APIEndpoint(path: "/scenarios/")
            )
            errorMessage = nil
        } catch {
            errorMessage = (error as? AppError)?.errorDescription ?? error.localizedDescription
        }
    }

    func create(_ input: ScenarioInput) async throws -> Scenario {
        let body = try JSONCoders.encoder.encode(input)
        return try await APIClient.shared.request(
            APIEndpoint(path: "/scenarios/", method: .post, body: body)
        )
    }

    func copyFromDefaults(id: Int) async throws -> Scenario {
        return try await APIClient.shared.request(
            APIEndpoint(path: "/scenarios/\(id)/copy_from_defaults/", method: .post)
        )
    }

    func delete(id: Int) async throws {
        try await APIClient.shared.requestVoid(
            APIEndpoint(path: "/scenarios/\(id)/", method: .delete)
        )
        items.removeAll { $0.id == id }
    }
}

@Observable
final class ScenarioDetailStore {
    var scenario: Scenario? = nil
    var summary: ScenarioSummary? = nil
    var isLoading: Bool = false
    var errorMessage: String? = nil

    let id: Int

    init(id: Int) {
        self.id = id
    }

    func fetch() async {
        isLoading = true
        defer { isLoading = false }
        do {
            scenario = try await APIClient.shared.request(
                APIEndpoint(path: "/scenarios/\(id)/")
            )
            errorMessage = nil
        } catch {
            errorMessage = (error as? AppError)?.errorDescription ?? error.localizedDescription
        }
    }

    func fetchSummary(mode: String, month: Int?) async {
        do {
            var query = [URLQueryItem(name: "mode", value: mode)]
            if mode == "monthly", let month {
                query.append(URLQueryItem(name: "month", value: String(month)))
            }
            summary = try await APIClient.shared.request(
                APIEndpoint(path: "/scenarios/\(id)/summary/", queryItems: query)
            )
        } catch {
            errorMessage = (error as? AppError)?.errorDescription ?? error.localizedDescription
        }
    }

    func saveItem(_ input: ScenarioItemInput, itemID: Int?) async throws {
        let body = try JSONCoders.encoder.encode(input)
        if let itemID {
            _ = try await APIClient.shared.request(
                APIEndpoint(
                    path: "/scenario_items/\(itemID)/",
                    method: .put,
                    body: body
                )
            ) as ScenarioItem
        } else {
            _ = try await APIClient.shared.request(
                APIEndpoint(
                    path: "/scenario_items/",
                    method: .post,
                    body: body
                )
            ) as ScenarioItem
        }
    }

    func toggleItem(itemID: Int, isEnabled: Bool) async throws {
        let patch = ScenarioItemPatch(isEnabled: isEnabled)
        let body = try JSONCoders.encoder.encode(patch)
        _ = try await APIClient.shared.request(
            APIEndpoint(
                path: "/scenario_items/\(itemID)/",
                method: .patch,
                body: body
            )
        ) as ScenarioItem
    }

    func deleteItem(itemID: Int) async throws {
        try await APIClient.shared.requestVoid(
            APIEndpoint(path: "/scenario_items/\(itemID)/", method: .delete)
        )
    }

    func fetchHistoryAverage(name: String, months: Int = 3) async -> HistoryAverage? {
        do {
            return try await APIClient.shared.request(
                APIEndpoint(
                    path: "/expenses/history_average/",
                    queryItems: [
                        URLQueryItem(name: "name", value: name),
                        URLQueryItem(name: "months", value: String(months)),
                    ]
                )
            )
        } catch {
            return nil
        }
    }
}
