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

        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Create account")
                        .font(.largeTitle.weight(.semibold))
                    Text("Set up your account to start your financial plan.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 16) {
                    if let error = viewModel.errorMessage, !error.isEmpty {
                        AuthErrorBanner(message: error)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.subheadline.weight(.medium))
                        TextField("John", text: $viewModel.name)
                            .padding()
                            .background(.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                        if viewModel.name.isEmpty == false && trimmedName.isEmpty {
                            Text("Name cannot be only spaces.")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
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

                        if !trimmedEmail.isEmpty && !isEmailValid {
                            Text("Please enter a valid email address.")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.subheadline.weight(.medium))
                        SecureField("Minimum 8 characters", text: $viewModel.password)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding()
                            .background(.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                        if !viewModel.password.isEmpty && !isPasswordValid {
                            Text("Password must be at least 8 characters.")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirm Password")
                            .font(.subheadline.weight(.medium))
                        SecureField("Re-enter password", text: $viewModel.confirmPassword)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding()
                            .background(.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                        if !viewModel.confirmPassword.isEmpty && !doPasswordsMatch {
                            Text("Passwords do not match.")
                                .font(.caption)
                                .foregroundStyle(.red)
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
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundStyle(.white)
                        .background(canSubmit ? Color.blue : Color.gray, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .disabled(!canSubmit)

                    Button("Already have an account? Log In") {
                        coordinator.pop()
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
            .padding(.top, 24)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Register")
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
