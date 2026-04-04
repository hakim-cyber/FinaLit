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
                            .font(.system(size: 34, weight: .medium))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("Log in to continue your financial journey.")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AuthPalette.muted)
                    }

                    VStack(spacing: 16) {
                        if let error = viewModel.errorMessage, !error.isEmpty {
                            AuthErrorBanner(message: error)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .appFieldLabelStyle()
                            TextField("name@email.com", text: $viewModel.email)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                                .authInputStyle()
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .appFieldLabelStyle()
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
                            .font(.system(size: 12, weight: .semibold))
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
                                        .tint(AppTheme.inverseText)
                                }
                                Text(viewModel.isLoading ? "Logging In..." : "Log In")
                            }
                        }
                        .buttonStyle(AppFilledButtonStyle(tone: .accent))
                        .disabled(!canSubmit)

                        Button("Don't have an account? Create one") {
                            coordinator.push(.register)
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AuthPalette.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)

                        AuthLegalLinksRow()
                    }
                    .appSurface(.primary, padding: 20, cornerRadius: AppTheme.CornerRadius.large)
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
                            .font(.system(size: 34, weight: .medium))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("We will send a reset link to your email.")
                            .font(AppTheme.Typography.caption)
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
                            Text("Email")
                                .appFieldLabelStyle()
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
                                        .tint(AppTheme.inverseText)
                                }
                                Text(viewModel.isLoading ? "Sending..." : "Send Reset Link")
                            }
                        }
                        .buttonStyle(AppFilledButtonStyle(tone: .accent))
                        .disabled(!canSubmit)

                        Button("Back to Log In") {
                            coordinator.pop()
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AuthPalette.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)

                        AuthLegalLinksRow()
                    }
                    .appSurface(.primary, padding: 20, cornerRadius: AppTheme.CornerRadius.large)
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
                .foregroundStyle(AppTheme.danger)
            Text(message)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appSurface(.tinted(.danger), padding: 12, cornerRadius: AppTheme.CornerRadius.medium)
    }
}

private struct AuthSuccessBanner: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AppTheme.success)
            Text(message)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appSurface(.tinted(.success), padding: 12, cornerRadius: AppTheme.CornerRadius.medium)
    }
}

private enum AuthPalette {
    static let background = AppTheme.background
    static let surface = AppTheme.surfacePrimary
    static let border = AppTheme.separator
    static let muted = AppTheme.textSecondary
    static let accent = AppTheme.accent
    static let disabledText = AppTheme.textTertiary
}

private struct AuthInputFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .appInputStyle()
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
