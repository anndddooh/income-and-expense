import SwiftUI

struct StateBadge: View {
    let state: InexState

    var body: some View {
        Text(state.label)
            .font(.yutori(10.5, weight: .bold))
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(Palette.stateBackground(state), in: Capsule())
            .foregroundStyle(Palette.stateColor(state))
    }
}

/// フォームの「状態」行に使うセグメントコントロール。
/// トラックは segment-track、選択中のつまみは card 背景 + 状態カラー文字。
struct StatePickerRow: View {
    @Binding var state: InexState

    var body: some View {
        HStack {
            Text("状態")
                .font(.yutori(15, weight: .bold))
                .foregroundStyle(Palette.foreground)
            Spacer()
            HStack(spacing: 3) {
                ForEach(InexState.allCases) { option in
                    segment(option)
                }
            }
            .padding(3)
            .background(Palette.segmentTrack, in: Capsule())
        }
    }

    private func segment(_ option: InexState) -> some View {
        let isSelected = option == state
        return Text(option.label)
            .font(.yutori(12.5, weight: .bold))
            .foregroundStyle(isSelected ? Palette.stateColor(option) : Palette.mutedForeground)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background {
                if isSelected {
                    Capsule()
                        .fill(Palette.card)
                        .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
                }
            }
            .contentShape(Capsule())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.15)) { state = option }
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
