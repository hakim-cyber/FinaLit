import SwiftUI
import AuthenticationServices

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
                VStack(spacing: 28) {
                    VStack(spacing: 10) {
                        Text("Welcome back")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("Sign in to FinaLit to track your budget, goals, and monthly progress.")
                            .font(AppTheme.Typography.body)
                            .foregroundStyle(AuthPalette.muted)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 18) {
                        if let error = viewModel.errorMessage, !error.isEmpty {
                            AuthErrorBanner(message: error)
                        }

                        if let success = viewModel.successMessage, !success.isEmpty {
                            AuthSuccessBanner(message: success)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .appFieldLabelStyle()
                            TextField("Enter your email", text: $viewModel.email)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                                .authInputStyle()
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .appFieldLabelStyle()
                            SecureField("Enter your password", text: $viewModel.password)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .authInputStyle()
                        }

                        HStack(alignment: .center) {
                            Spacer(minLength: 0)
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
                                        .tint(AuthPalette.background)
                                }
                                Text(viewModel.isLoading ? "Logging in..." : "Login")
                            }
                        }
                        .buttonStyle(AuthPrimaryActionButtonStyle())
                        .disabled(!canSubmit)

                        AuthDividerLabel(text: "OR")

                        AuthAppleSignInButton(
                            onRequest: viewModel.prepareAppleSignInRequest,
                            onCompletion: { result in
                                Task {
                                    await viewModel.continueWithApple(result: result)
                                }
                            }
                        )
                        .disabled(viewModel.isLoading)

                        Button {
                            Task {
                                await viewModel.continueWithGoogle()
                            }
                        } label: {
                            AuthSocialButton(
                                title: "Continue with Google",
                                icon: .google
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.isLoading)
                    }

                    VStack(spacing: 14) {
                        AuthLegalLinksRow()

                        Button("Don't have a FinaLit account? Sign up") {
                            coordinator.push(.register)
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AuthPalette.accent)
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(maxWidth: 420)
                .padding(.horizontal, 24)
                .padding(.top, 56)
                .padding(.bottom, 32)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onChange(of: viewModel.email) { _, _ in
            viewModel.clearMessages()
        }
        .onChange(of: viewModel.password) { _, _ in
            viewModel.clearMessages()
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
                            TextField("Enter your email", text: $viewModel.email)
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
    static let surfaceSecondary = AppTheme.surfaceSecondary
    static let border = AppTheme.separator
    static let muted = AppTheme.textSecondary
    static let accent = AppTheme.accent
    static let disabledText = AppTheme.textTertiary
}

private struct AuthInputFieldModifier: ViewModifier {
    private let cornerRadius: CGFloat = 24

    func body(content: Content) -> some View {
        content
            .font(AppTheme.Typography.body)
            .foregroundStyle(AppTheme.textPrimary)
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .frame(minHeight: 54)
            .background(AuthPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AuthPalette.border, lineWidth: 1)
            )
    }
}

private extension View {
    func authInputStyle() -> some View {
        modifier(AuthInputFieldModifier())
    }
}

private struct AuthPrimaryActionButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    private let cornerRadius: CGFloat = 24

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(AuthPalette.background)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(isEnabled ? Color.primary : AuthPalette.border)
            )
            .opacity(configuration.isPressed ? 0.92 : 1)
    }
}

private struct AuthDividerLabel: View {
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(AuthPalette.border)
                .frame(height: 1)
            Text(text)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AuthPalette.muted)
            Rectangle()
                .fill(AuthPalette.border)
                .frame(height: 1)
        }
    }
}

private struct AuthSocialButton: View {
    private let cornerRadius: CGFloat = 24

    enum Icon {
        case google
    }

    let title: String
    let icon: Icon

    var body: some View {
        HStack(spacing: 12) {
            iconView
                .frame(width: 22, height: 22)
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.textPrimary)
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(AuthPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(AuthPalette.border, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var iconView: some View {
        switch icon {
        case .google:
            Image(.googleLogo)
                .resizable()
                .frame(width: 18,height: 18)
                .scaledToFit()
                
        }
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
