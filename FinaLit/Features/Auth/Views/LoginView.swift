import SwiftUI

struct LoginView: View {
    @Environment(AuthViewModel.self) private var viewModel
    @Environment(Coordinator<AuthPages>.self) private var coordinator

    private var isEmailValid: Bool {
        let trimmed = viewModel.email.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.contains("@") && trimmed.contains(".")
    }

    private var canSubmit: Bool {
        viewModel.isLoginFormValid && isEmailValid && !viewModel.isLoading
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        ZStack {
            AuthPalette.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Welcome back")
                            .font(.system(size: 34, weight: .light, design: .serif))
                            .foregroundStyle(.white)
                        Text("Log in to continue your financial journey.")
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundStyle(AuthPalette.muted)
                    }

                    VStack(spacing: 16) {
                        if let error = viewModel.errorMessage, !error.isEmpty {
                            AuthErrorBanner(message: error)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("EMAIL")
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                .foregroundStyle(AuthPalette.muted)
                            TextField("name@email.com", text: $viewModel.email)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                                .authInputStyle()
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("PASSWORD")
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                .foregroundStyle(AuthPalette.muted)
                            SecureField("Enter password", text: $viewModel.password)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .authInputStyle()
                        }

                        HStack {
                            Spacer()
                            Button("Forgot password?") {
                                coordinator.push(.forgotPassword)
                            }
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(AuthPalette.accent)
                        }

                        Button {
                            Task {
                                await viewModel.login()
                            }
                        } label: {
                            HStack(spacing: 10) {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .tint(.white)
                                }
                                Text(viewModel.isLoading ? "Logging In..." : "Log In")
                                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .foregroundStyle(canSubmit ? .white : AuthPalette.disabledText)
                            .background(
                                LinearGradient(
                                    colors: canSubmit
                                        ? [Color(hex: "6366F1"), Color(hex: "4F46E5")]
                                        : [AuthPalette.border, AuthPalette.border],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(!canSubmit)

                        Button("Don't have an account? Create one") {
                            coordinator.push(.register)
                        }
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundStyle(AuthPalette.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)
                    }
                    .padding(20)
                    .background(AuthPalette.surface, in: RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AuthPalette.border, lineWidth: 1)
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 48)
                .padding(.bottom, 24)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onChange(of: viewModel.email) { _, _ in
            viewModel.clearError()
        }
        .onChange(of: viewModel.password) { _, _ in
            viewModel.clearError()
        }
    }
}

struct ForgotPasswordView: View {
    @Environment(AuthViewModel.self) private var viewModel
    @Environment(Coordinator<AuthPages>.self) private var coordinator

    private var isEmailValid: Bool {
        let trimmed = viewModel.email.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.contains("@") && trimmed.contains(".")
    }

    private var canSubmit: Bool {
        isEmailValid && !viewModel.isLoading
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        ZStack {
            AuthPalette.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Reset password")
                            .font(.system(size: 34, weight: .light, design: .serif))
                            .foregroundStyle(.white)
                        Text("We will send a reset link to your email.")
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundStyle(AuthPalette.muted)
                    }

                    VStack(spacing: 16) {
                        if let error = viewModel.errorMessage, !error.isEmpty {
                            AuthErrorBanner(message: error)
                        }

                        if let success = viewModel.successMessage, !success.isEmpty {
                            AuthSuccessBanner(message: success)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("EMAIL")
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                .foregroundStyle(AuthPalette.muted)
                            TextField("name@email.com", text: $viewModel.email)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                                .authInputStyle()
                        }

                        Button {
                            Task {
                                await viewModel.sendPasswordReset()
                            }
                        } label: {
                            HStack(spacing: 10) {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .tint(.white)
                                }
                                Text(viewModel.isLoading ? "Sending..." : "Send Reset Link")
                                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .foregroundStyle(canSubmit ? .white : AuthPalette.disabledText)
                            .background(
                                LinearGradient(
                                    colors: canSubmit
                                        ? [Color(hex: "6366F1"), Color(hex: "4F46E5")]
                                        : [AuthPalette.border, AuthPalette.border],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(!canSubmit)

                        Button("Back to Log In") {
                            coordinator.pop()
                        }
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundStyle(AuthPalette.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)
                    }
                    .padding(20)
                    .background(AuthPalette.surface, in: RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AuthPalette.border, lineWidth: 1)
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 48)
                .padding(.bottom, 24)
            }
        }
        .onChange(of: viewModel.email) { _, _ in
            viewModel.clearMessages()
        }
    }
}

private struct AuthErrorBanner: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color(hex: "F87171"))
            Text(message)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Color(hex: "FCA5A5"))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "450A0A").opacity(0.45), in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(hex: "7F1D1D"), lineWidth: 1)
        )
    }
}

private struct AuthSuccessBanner: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color(hex: "10B981"))
            Text(message)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Color(hex: "6EE7B7"))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "052E16").opacity(0.45), in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(hex: "166534"), lineWidth: 1)
        )
    }
}

private enum AuthPalette {
    static let background = Color(hex: "0A0A0F")
    static let surface = Color(hex: "111118")
    static let border = Color(hex: "1F2937")
    static let muted = Color(hex: "6B7280")
    static let accent = Color(hex: "6366F1")
    static let disabledText = Color(hex: "4B5563")
}

private struct AuthInputFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 15, design: .serif))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .frame(height: 50)
            .background(AuthPalette.background.opacity(0.8), in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AuthPalette.border, lineWidth: 1)
            )
    }
}

private extension View {
    func authInputStyle() -> some View {
        modifier(AuthInputFieldModifier())
    }
}

#Preview("Login - Default") {
    LoginPreviewContainer(variant: .default)
}

#Preview("Login - Error") {
    LoginPreviewContainer(variant: .error)
}

private struct LoginPreviewContainer: View {
    enum PreviewVariant {
        case `default`
        case error
    }

    @State private var viewModel: AuthViewModel
    private let coordinator = Coordinator<AuthPages>()

    init(variant: PreviewVariant) {
        let viewModel = AuthViewModel(
            authService: AuthService(),
            dbService: DatabaseService(),
            session: UserSession()
        )

        viewModel.email = "alex@finalit.app"
        viewModel.password = "password123"

        if variant == .error {
            viewModel.errorMessage = "No account found with this email."
        }

        _viewModel = SwiftUI.State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            LoginView()
        }
        .environment(viewModel)
        .environment(coordinator)
    }
}
