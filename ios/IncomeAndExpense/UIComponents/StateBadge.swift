import SwiftUI

struct StateBadge: View {
    let state: InexState

    var body: some View {
        Text(state.label)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(backgroundColor.opacity(0.2), in: Capsule())
            .foregroundStyle(backgroundColor)
    }

    private var backgroundColor: Color {
        switch state {
        case .undecided: return Palette.pending
        case .decided: return .accentColor
        case .done: return Palette.income
        }
    }
}

#Preview {
    VStack(spacing: 8) {
        StateBadge(state: .undecided)
        StateBadge(state: .decided)
        StateBadge(state: .done)
    }
    .padding()
}
