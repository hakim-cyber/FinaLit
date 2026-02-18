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

        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome back")
                        .font(.largeTitle.weight(.semibold))
                    Text("Log in to continue managing your finances.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 16) {
                    if let error = viewModel.errorMessage, !error.isEmpty {
                        AuthErrorBanner(message: error)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.subheadline.weight(.medium))
                        TextField("name@email.com", text: $viewModel.email)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .padding()
                            .background(.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.subheadline.weight(.medium))
                        SecureField("Enter password", text: $viewModel.password)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding()
                            .background(.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundStyle(.white)
                        .background(canSubmit ? Color.blue : Color.gray, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .disabled(!canSubmit)

                    Button("Dont have acount") {
                        coordinator.push(.register)
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
                }
                .padding(20)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding(.horizontal, 20)
            .padding(.top, 48)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .onChange(of: viewModel.email) { _, _ in
            viewModel.clearError()
        }
        .onChange(of: viewModel.password) { _, _ in
            viewModel.clearError()
        }
    }
}

private struct AuthErrorBanner: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text(message)
                .font(.footnote)
                .foregroundStyle(.red)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
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
