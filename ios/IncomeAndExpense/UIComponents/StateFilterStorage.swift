import Foundation
import Observation

@Observable
final class StateFilterStorage {
    private let key: String

    var selected: Set<InexState> {
        didSet { save() }
    }

    init(key: String) {
        self.key = key
        if let raw = UserDefaults.standard.array(forKey: key) as? [Int] {
            let states = raw.compactMap { InexState(rawValue: $0) }
            self.selected = states.isEmpty
                ? Set(InexState.allCases)
                : Set(states)
        } else {
            self.selected = Set(InexState.allCases)
        }
    }

    private func save() {
        let raw = selected.map { $0.rawValue }
        UserDefaults.standard.set(raw, forKey: key)
    }
}
