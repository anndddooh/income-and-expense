import SwiftUI

struct LoginView: View {
    @State private var viewModel = LoginViewModel()

    var body: some View {
        @Bindable var viewModel = viewModel
        ZStack {
            Palette.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    VStack(spacing: 10) {
                        Image("AppLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        Text("INEX にログイン")
                            .font(.yutori(21, weight: .heavy))
                            .foregroundStyle(Palette.foreground)
                        Text("家計をひと目で、ゆとりのある毎日へ。")
                            .font(.yutori(12.5))
                            .foregroundStyle(Palette.mutedForeground)
                            .multilineTextAlignment(.center)
                    }

                    VStack(spacing: 12) {
                        input {
                            TextField("ユーザー名", text: $viewModel.username)
                                .textContentType(.username)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .submitLabel(.next)
                        }
                        input {
                            SecureField("パスワード", text: $viewModel.password)
                                .textContentType(.password)
                                .submitLabel(.go)
                                .onSubmit {
                                    Task { await viewModel.submit() }
                                }
                        }

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.yutori(12))
                                .foregroundStyle(Palette.expense)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button {
                            Task { await viewModel.submit() }
                        } label: {
                            HStack {
                                Spacer()
                                if viewModel.isLoading {
                                    ProgressView().tint(Palette.card)
                                } else {
                                    Text("ログイン")
                                        .font(.yutori(15, weight: .bold))
                                }
                                Spacer()
                            }
                            .frame(height: 48)
                            .foregroundStyle(Palette.card)
                            .background(Palette.primary, in: Capsule())
                            .opacity(viewModel.canSubmit ? 1 : 0.5)
                        }
                        .buttonStyle(.plain)
                        .disabled(!viewModel.canSubmit)
                        .padding(.top, 4)
                    }
                    .padding(22)
                    .yutoriCard()
                }
                .padding(20)
                .frame(maxWidth: 480)
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
            }
        }
    }

    private func input<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .font(.yutori(15))
            .foregroundStyle(Palette.foreground)
            .padding(.horizontal, 14)
            .frame(height: 42)
            .background(Palette.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Palette.inputBorder, lineWidth: 1)
            )
    }
}

#Preview {
    LoginView()
}
