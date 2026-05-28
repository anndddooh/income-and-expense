import SwiftUI

/// List 内に置く「読み込み中」または「空」のプレースホルダ行。
/// 各一覧画面で空状態・初回ロードの見せ方を統一するために使う。
struct PlaceholderRow: View {
    enum Kind {
        case loading
        case empty(icon: String, message: String)
    }

    let kind: Kind

    var body: some View {
        HStack {
            Spacer()
            content
            Spacer()
        }
        .padding(.vertical, 32)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    @ViewBuilder
    private var content: some View {
        switch kind {
        case .loading:
            ProgressView()
        case let .empty(icon, message):
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 38))
                    .foregroundStyle(.tertiary)
                Text(message)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}
