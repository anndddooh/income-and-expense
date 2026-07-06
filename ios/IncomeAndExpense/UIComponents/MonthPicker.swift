import SwiftUI

/// 各タブのツールバーに表示する年月ピッカー。
/// 左右の矢印で前後月、中央をタップでホイール式の年月選択シートを開く。
struct MonthPicker: View {
    @Bindable var store: MonthStore
    @State private var showingSheet = false

    var body: some View {
        HStack(spacing: 16) {
            Button {
                store.goToPreviousMonth()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Palette.primaryStrong)
            }

            Button {
                showingSheet = true
            } label: {
                Text(verbatim: "\(store.year)年\(store.month)月")
                    .font(.yutori(15, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(Palette.foreground)
            }

            Button {
                store.goToNextMonth()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Palette.primaryStrong)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 36)
        .background(Palette.card, in: Capsule())
        .overlay(Capsule().stroke(Palette.inputBorder, lineWidth: 1))
        .sheet(isPresented: $showingSheet) {
            MonthPickerSheet(store: store)
                .presentationDetents([.height(340)])
        }
    }
}

private struct MonthPickerSheet: View {
    @Bindable var store: MonthStore
    @Environment(\.dismiss) private var dismiss

    private static let years: [Int] = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? .current
        let current = calendar.component(.year, from: Date())
        return Array((current - 10)...(current + 5))
    }()

    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                Picker("年", selection: $store.year) {
                    ForEach(Self.years, id: \.self) { year in
                        Text(verbatim: "\(year)年").tag(year)
                    }
                }
                .pickerStyle(.wheel)

                Picker("月", selection: $store.month) {
                    ForEach(1...12, id: \.self) { month in
                        Text(verbatim: "\(month)月").tag(month)
                    }
                }
                .pickerStyle(.wheel)
            }
            .navigationTitle("年月を選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("今月") { store.resetToCurrent() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完了") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}
