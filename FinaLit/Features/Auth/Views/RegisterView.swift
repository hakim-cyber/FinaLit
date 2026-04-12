import SwiftUI
import AuthenticationServices

struct RegisterView: View {
    @Environment(AuthViewModel.self) private var viewModel
    @Environment(Coordinator<AuthPages>.self) private var coordinator

    private var trimmedName: String {
        viewModel.name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedEmail: String {
        viewModel.email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isEmailValid: Bool {
        trimmedEmail.contains("@") && trimmedEmail.contains(".")
    }

    private var isPasswordValid: Bool {
        viewModel.password.count >= 8
    }

    private var doPasswordsMatch: Bool {
        !viewModel.confirmPassword.isEmpty && viewModel.password == viewModel.confirmPassword
    }

    private var canSubmit: Bool {
        !trimmedName.isEmpty &&
        isEmailValid &&
        isPasswordValid &&
        doPasswordsMatch &&
        !viewModel.isLoading
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        ZStack {
            AuthPalette.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    VStack(spacing: 10) {
                        Text(L10n.Auth.createYourFinalitAccount)
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text(L10n.Auth.startBudgetingBuildGoalsAndOrganizeYourFinancialLifeInOnePlace)
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
                            Text(L10n.Auth.name)
                                .appFieldLabelStyle()
                            TextField(L10n.Auth.enterYourName, text: $viewModel.name)
                                .authInputStyle()

                            if viewModel.name.isEmpty == false && trimmedName.isEmpty {
                                Text(L10n.Auth.nameCannotBeOnlySpaces)
                                    .font(AppTheme.Typography.detail)
                                    .foregroundStyle(AppTheme.danger)
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text(L10n.Auth.email)
                                .appFieldLabelStyle()
                            TextField(L10n.Auth.enterYourEmail, text: $viewModel.email)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                                .authInputStyle()

                            if !trimmedEmail.isEmpty && !isEmailValid {
                                Text(L10n.Auth.pleaseEnterAValidEmailAddress)
                                    .font(AppTheme.Typography.detail)
                                    .foregroundStyle(AppTheme.danger)
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text(L10n.Auth.password)
                                .appFieldLabelStyle()
                            SecureField("Enter your password", text: $viewModel.password)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .authInputStyle()

                            if !viewModel.password.isEmpty && !isPasswordValid {
                                Text(L10n.Auth.passwordMustBeAtLeast8Characters)
                                    .font(AppTheme.Typography.detail)
                                    .foregroundStyle(AppTheme.danger)
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text(L10n.Auth.confirmPassword)
                                .appFieldLabelStyle()
                            SecureField("Confirm your password", text: $viewModel.confirmPassword)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .authInputStyle()

                            if !viewModel.confirmPassword.isEmpty && !doPasswordsMatch {
                                Text(L10n.Auth.passwordsDoNotMatch)
                                    .font(AppTheme.Typography.detail)
                                    .foregroundStyle(AppTheme.danger)
                            }
                        }

                        Button {
                            Task {
                                await viewModel.register()
                            }
                        } label: {
                            HStack(spacing: 10) {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .tint(AuthPalette.background)
                                }
                                Text(viewModel.isLoading ? "Creating account..." : "Sign up")
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

                        Button(L10n.Auth.alreadyHaveAFinalitAccountLogin) {
                            coordinator.pop()
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
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.shouldReturnToLoginAfterRegister) { _, shouldReturn in
            guard shouldReturn else { return }
            viewModel.consumeRegisterRedirect()
            coordinator.pop()
        }
        .onChange(of: viewModel.name) { _, _ in
            viewModel.clearMessages()
        }
        .onChange(of: viewModel.email) { _, _ in
            viewModel.clearMessages()
        }
        .onChange(of: viewModel.password) { _, _ in
            viewModel.clearMessages()
        }
        .onChange(of: viewModel.confirmPassword) { _, _ in
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

#Preview("Register - Default") {
    RegisterPreviewContainer(variant: .default)
}

#Preview("Register - Validation") {
    RegisterPreviewContainer(variant: .validation)
}

private struct RegisterPreviewContainer: View {
    enum PreviewVariant {
        case `default`
        case validation
    }

    @State private var viewModel: AuthViewModel
    private let coordinator = Coordinator<AuthPages>()

    init(variant: PreviewVariant) {
        let viewModel = AuthViewModel(
            authService: AuthService(),
            dbService: DatabaseService(),
            session: UserSession()
        )

        switch variant {
        case .default:
            viewModel.name = "Alex"
            viewModel.email = "alex@finalit.app"
            viewModel.password = "password123"
            viewModel.confirmPassword = "password123"
        case .validation:
            viewModel.name = "  "
            viewModel.email = "alexfinalit.app"
            viewModel.password = "pass"
            viewModel.confirmPassword = "pass1234"
            viewModel.errorMessage = "Please enter a valid email address."
        }

        _viewModel = SwiftUI.State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            RegisterView()
        }
        .environment(viewModel)
        .environment(coordinator)
    }
}
