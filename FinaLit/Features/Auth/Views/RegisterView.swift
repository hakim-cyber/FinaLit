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
                            .foregroundStyle(.white)
                        Text("Set up your profile to personalize your financial path.")
                            .font(.system(size: 13))
                            .foregroundStyle(AuthPalette.muted)
                    }

                    VStack(spacing: 16) {
                        if let error = viewModel.errorMessage, !error.isEmpty {
                            AuthErrorBanner(message: error)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("NAME")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(AuthPalette.muted)
                            TextField("John", text: $viewModel.name)
                                .authInputStyle()

                            if viewModel.name.isEmpty == false && trimmedName.isEmpty {
                                Text("Name cannot be only spaces.")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color(hex: "F87171"))
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("EMAIL")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(AuthPalette.muted)
                            TextField("name@email.com", text: $viewModel.email)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                                .authInputStyle()

                            if !trimmedEmail.isEmpty && !isEmailValid {
                                Text("Please enter a valid email address.")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color(hex: "F87171"))
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("PASSWORD")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(AuthPalette.muted)
                            SecureField("Minimum 8 characters", text: $viewModel.password)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .authInputStyle()

                            if !viewModel.password.isEmpty && !isPasswordValid {
                                Text("Password must be at least 8 characters.")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color(hex: "F87171"))
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("CONFIRM PASSWORD")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(AuthPalette.muted)
                            SecureField("Re-enter password", text: $viewModel.confirmPassword)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .authInputStyle()

                            if !viewModel.confirmPassword.isEmpty && !doPasswordsMatch {
                                Text("Passwords do not match.")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color(hex: "F87171"))
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
                                        .tint(.white)
                                }
                                Text(viewModel.isLoading ? "Creating..." : "Create Account")
                                    .font(.system(size: 15, weight: .semibold))
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

                        Button("Already have an account? Log In") {
                            coordinator.pop()
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AuthPalette.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)

                        AuthLegalLinksRow()
                    }
                    .padding(20)
                    .background(AuthPalette.surface, in: RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AuthPalette.border, lineWidth: 1)
                    )
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
                .foregroundStyle(Color(hex: "F87171"))
            Text(message)
                .font(.system(size: 12))
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
            .font(.system(size: 15))
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
