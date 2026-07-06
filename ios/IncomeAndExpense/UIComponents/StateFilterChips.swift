import SwiftUI

struct StateFilterChips: View {
    @Binding var selected: Set<InexState>

    var body: some View {
        HStack(spacing: 8) {
            Text("状態:")
                .font(.yutori(12))
                .foregroundStyle(Palette.mutedForeground)
            ForEach(InexState.allCases) { state in
                chip(state)
            }
            Spacer()
        }
    }

    private func chip(_ state: InexState) -> some View {
        let isActive = selected.contains(state)
        let tint = Palette.stateColor(state)
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
                .font(.yutori(11.5, weight: .bold))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .foregroundStyle(isActive ? tint : Palette.mutedForeground)
                .background(
                    isActive ? tint.opacity(0.16) : Color.clear,
                    in: Capsule()
                )
                .overlay(
                    Capsule().stroke(
                        isActive ? tint.opacity(0.4) : Palette.inputBorder,
                        lineWidth: 1
                    )
                )
        }
        .buttonStyle(.plain)
    }
}
