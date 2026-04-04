import SwiftUI

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
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Create account")
                            .font(.system(size: 34, weight: .medium))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("Set up your profile to personalize your financial path.")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AuthPalette.muted)
                    }

                    VStack(spacing: 16) {
                        if let error = viewModel.errorMessage, !error.isEmpty {
                            AuthErrorBanner(message: error)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name")
                                .appFieldLabelStyle()
                            TextField("John", text: $viewModel.name)
                                .authInputStyle()

                            if viewModel.name.isEmpty == false && trimmedName.isEmpty {
                                Text("Name cannot be only spaces.")
                                    .font(AppTheme.Typography.detail)
                                    .foregroundStyle(AppTheme.danger)
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .appFieldLabelStyle()
                            TextField("name@email.com", text: $viewModel.email)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                                .authInputStyle()

                            if !trimmedEmail.isEmpty && !isEmailValid {
                                Text("Please enter a valid email address.")
                                    .font(AppTheme.Typography.detail)
                                    .foregroundStyle(AppTheme.danger)
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .appFieldLabelStyle()
                            SecureField("Minimum 8 characters", text: $viewModel.password)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .authInputStyle()

                            if !viewModel.password.isEmpty && !isPasswordValid {
                                Text("Password must be at least 8 characters.")
                                    .font(AppTheme.Typography.detail)
                                    .foregroundStyle(AppTheme.danger)
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm password")
                                .appFieldLabelStyle()
                            SecureField("Re-enter password", text: $viewModel.confirmPassword)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .authInputStyle()

                            if !viewModel.confirmPassword.isEmpty && !doPasswordsMatch {
                                Text("Passwords do not match.")
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
                                        .tint(AppTheme.inverseText)
                                }
                                Text(viewModel.isLoading ? "Creating..." : "Create Account")
                            }
                        }
                        .buttonStyle(AppFilledButtonStyle(tone: .accent))
                        .disabled(!canSubmit)

                        Button("Already have an account? Log In") {
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
                .padding(.top, 24)
                .padding(.bottom, 24)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.name) { _, _ in
            viewModel.clearError()
        }
        .onChange(of: viewModel.email) { _, _ in
            viewModel.clearError()
        }
        .onChange(of: viewModel.password) { _, _ in
            viewModel.clearError()
        }
        .onChange(of: viewModel.confirmPassword) { _, _ in
            viewModel.clearError()
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
