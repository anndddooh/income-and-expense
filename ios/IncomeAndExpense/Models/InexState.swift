import Foundation

enum InexState: Int, Codable, CaseIterable, Identifiable {
    case undecided = 0
    case decided = 1
    case done = 2

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .undecided: return "未確定"
        case .decided: return "確定"
        case .done: return "完了"
        }
    }
}
