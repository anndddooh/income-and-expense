import SwiftUI

struct StateFilterChips: View {
    @Binding var selected: Set<InexState>

    var body: some View {
        HStack(spacing: 8) {
            Text("状態:")
                .font(.caption)
                .foregroundStyle(.secondary)
            ForEach(InexState.allCases) { state in
                chip(state)
            }
            Spacer()
        }
    }

    private func chip(_ state: InexState) -> some View {
        let isActive = selected.contains(state)
        let tint = backgroundColor(state)
        return Button {
            if isActive {
                if selected.count > 0 {
                    selected.remove(state)
                }
            } else {
                selected.insert(state)
            }
        } label: {
            Text(state.label)
                .font(.caption2.weight(.medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .foregroundStyle(isActive ? tint : Color.secondary)
                .background(
                    isActive ? tint.opacity(0.18) : Color.clear,
                    in: Capsule()
                )
                .overlay(
                    Capsule().stroke(
                        isActive ? tint.opacity(0.4) : Color.secondary.opacity(0.3),
                        lineWidth: 1
                    )
                )
        }
        .buttonStyle(.plain)
    }

    private func backgroundColor(_ state: InexState) -> Color {
        switch state {
        case .undecided: return Palette.pending
        case .decided: return .accentColor
        case .done: return Palette.income
        }
    }
}
