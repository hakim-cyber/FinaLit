//
//  AuthViewModel.swift
//  FinaLit
//
//  Created by aplle on 2/18/26.
//


// AuthViewModel.swift
// Features/Auth/ViewModels/
//
// Drives all auth screens: Login, Register, ForgotPassword.
// One ViewModel for the whole auth flow — screens bind to the same instance.
// Injected as @State in the auth CoordinatorStack root, shared via .environment()

import SwiftUI
import AuthenticationServices
#if canImport(UIKit)
import UIKit
#endif

@Observable
class AuthViewModel {

    // MARK: - Form State
    // Bound directly to TextFields in views
    var name: String     = ""
    var email: String    = ""
    var password: String = ""
    var confirmPassword: String = ""

    // MARK: - UI State
    var isLoading: Bool    = false
    var errorMessage: String?
    var successMessage: String?
    var postRegistrationVerificationAlert: String?
    var shouldReturnToLoginAfterRegister: Bool = false
    private(set) var lastAuthError: AuthError?
    private var currentAppleNonce: String?

    // MARK: - Validation
    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isEmailValid: Bool {
        trimmedEmail.contains("@") && trimmedEmail.contains(".")
    }

    var isLoginFormValid: Bool {
        isEmailValid && !password.isEmpty
    }

    var isRegisterFormValid: Bool {
        !trimmedName.isEmpty &&
        isEmailValid &&
        password.count >= 8 &&
        password == confirmPassword
    }

    var needsReauthenticationForDeletion: Bool {
        lastAuthError == .requiresRecentLogin
    }

    // MARK: - Dependencies
    private let authService: AuthService
    private let dbService: DatabaseService
    private let session: UserSession

    init(authService: AuthService, dbService: DatabaseService, session: UserSession) {
        self.authService = authService
        self.dbService   = dbService
        self.session     = session
    }

    private func localized(_ text: String, _ arguments: CVarArg...) -> String {
        guard !arguments.isEmpty else { return text }
        return String(format: text, locale: Locale(identifier: "en_US_POSIX"), arguments: arguments)
    }

    // MARK: - Register
    func register() async {
        guard isRegisterFormValid else {
            if trimmedName.isEmpty {
                errorMessage = localized("Please enter your name.")
            } else if !isEmailValid {
                errorMessage = localized("Please enter a valid email address.")
            } else if password.count < 8 {
                errorMessage = localized("Password must be at least 8 characters.")
            } else if password != confirmPassword {
                errorMessage = localized("Passwords do not match.")
            } else {
                errorMessage = localized("Please fill in all fields.")
            }
            return
        }

        isLoading    = true
        clearMessages()
        defer { isLoading = false }

        do {
            _ = try await authService.register(email: trimmedEmail, password: password)

            do {
                try await authService.sendCurrentUserEmailVerification()
                postRegistrationVerificationAlert = localized("Your FinaLit account was created and we sent a verification email. Verify your address, then log in.")
                shouldReturnToLoginAfterRegister = true
            } catch {
                errorMessage = localized("Your account was created, but we couldn't send the verification email. Try logging in to resend it.")
            }

            try? authService.signOut()
            session.signOut()
            password = ""
            confirmPassword = ""

        } catch {
            handleError(error)
        }
    }

    // MARK: - Login
    func login() async {
        guard isLoginFormValid else {
            errorMessage = localized("Please enter a valid email and password.")
            return
        }

        isLoading = true
        clearMessages()
        defer { isLoading = false }

        do {
            let uid = try await authService.login(email: trimmedEmail, password: password)
            try await authService.reloadCurrentUser()

            if authService.currentUserRequiresEmailVerification && !authService.isCurrentUserEmailVerified {
                let resentVerification = (try? await authService.sendCurrentUserEmailVerification()) != nil
                try? authService.signOut()
                session.signOut()
                lastAuthError = .emailNotVerified
                errorMessage = resentVerification
                    ? localizedAuthError(.emailNotVerified)
                    : localized("Verify your email first, then log in again.")
                return
            }

            let user: User
            do {
                user = try await dbService.fetchUser(uid: uid)
            } catch DBError.userNotFound {
                let fallbackName = trimmedName.isEmpty
                    ? (trimmedEmail.split(separator: "@").first.map(String.init) ?? "User")
                    : trimmedName
                let recoveredUser = User(
                    id: uid,
                    email: trimmedEmail,
                    name: fallbackName,
                    createdAt: .now,
                    preferences: UserPreferences()
                )
                try dbService.createUser(recoveredUser)
                user = recoveredUser
            }

            session.setUser(user)

        } catch {
            handleError(error)
        }
    }

    // MARK: - Forgot Password
    func sendPasswordReset() async {
        await sendPasswordReset(to: email)
    }

    func sendPasswordReset(to rawEmail: String) async {
        let trimmedEmail = rawEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else {
            errorMessage = localized("Please enter your email address.")
            return
        }

        isLoading      = true
        errorMessage   = nil
        successMessage = nil
        defer { isLoading = false }

        do {
            try await authService.sendPasswordReset(email: trimmedEmail)
            successMessage = localized("Password reset email sent. Check your inbox.")
        } catch {
            handleError(error)
        }
    }

    // MARK: - Social Sign-In Placeholders
    func prepareAppleSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        clearMessages()
        let nonce = authService.randomNonceString()
        currentAppleNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = authService.sha256(nonce)
    }

    func continueWithApple(result: Result<ASAuthorization, Error>) async {
        guard !isLoading else { return }

        clearMessages()
        isLoading = true
        defer {
            isLoading = false
            currentAppleNonce = nil
        }

        do {
            let authorization: ASAuthorization
            switch result {
            case .success(let authorizationRes):
                authorization = authorizationRes
            case .failure(let error):
                throw mapAppleError(error)
            }

            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                throw AuthError.invalidAppleCredential
            }

            guard let idTokenData = credential.identityToken,
                  let idTokenString = String(data: idTokenData, encoding: .utf8) else {
                throw AuthError.missingIdentityToken
            }

            guard let currentAppleNonce, !currentAppleNonce.isEmpty else {
                throw AuthError.invalidAppleCredential
            }

            let identity = try await authService.signInWithApple(
                idTokenString: idTokenString,
                rawNonce: currentAppleNonce,
                fullName: credential.fullName
            )

            try await completeSocialLogin(identity: identity)
        } catch {
            handleError(error)
        }
    }

    func continueWithGoogle() async {
        guard !isLoading else { return }

        clearMessages()

#if canImport(UIKit)
        guard let presentingViewController = SocialAuthPresenter.current() else {
            handleError(AuthError.unableToPresentSocialSignIn)
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let identity = try await authService.signInWithGoogle(presenting: presentingViewController)
            try await completeSocialLogin(identity: identity)
        } catch {
            handleError(error)
        }
#else
        handleError(AuthError.providerUnavailable("Google Sign-In is only available on iOS."))
#endif
    }

    // MARK: - Sign Out
    // Called from Profile tab or anywhere in main app
    func signOut() {
        do {
            try authService.signOut()
            session.signOut()  // clears session → RootView shows auth again
            clearForm()
        } catch {
            handleError(error)
        }
    }

    // MARK: - Delete Account
    func deleteAccount() async {
        guard let uid = session.user?.id else {
            errorMessage = String(localized: "profile.sessionExpired")
            return
        }

        isLoading = true
        clearMessages()
        defer { isLoading = false }

        do {
            try await authService.ensureRecentLoginForSensitiveOperation()
            try await performAccountDeletion(uid: uid)
        } catch {
            handleError(error)
        }
    }

    func reauthenticateForAccountDeletion(password: String) async -> Bool {
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPassword.isEmpty else {
            errorMessage = localized("Please enter your password.")
            return false
        }

        guard let email = session.user?.email, !email.isEmpty else {
            errorMessage = localized("Email is unavailable for this account.")
            return false
        }

        isLoading = true
        clearMessages()
        defer { isLoading = false }

        do {
            try await authService.reauthenticateCurrentUser(email: email, password: trimmedPassword)
            successMessage = localized("Identity confirmed.")
            return true
        } catch {
            handleError(error)
            return false
        }
    }

    // MARK: - Helpers
    func clearError() {
        errorMessage = nil
        lastAuthError = nil
    }

    func clearMessages() {
        errorMessage = nil
        successMessage = nil
        lastAuthError = nil
    }

    func consumeRegisterRedirect() {
        shouldReturnToLoginAfterRegister = false
    }

    func dismissPostRegistrationVerificationAlert() {
        postRegistrationVerificationAlert = nil
    }

    private func clearForm() {
        name            = ""
        email           = ""
        password        = ""
        confirmPassword = ""
        errorMessage    = nil
        successMessage  = nil
        lastAuthError   = nil
    }

    private func performAccountDeletion(uid: String) async throws {
        // Keep data deletion before auth deletion while user is still authenticated.
        try await dbService.deleteAllUserData(uid: uid)
        try await authService.deleteCurrentUser()
        session.signOut()
        clearForm()
    }

    private func completeSocialLogin(identity: AuthenticatedIdentity) async throws {
        do {
            let user = try await dbService.fetchUser(uid: identity.uid)
            session.setUser(user)
        } catch DBError.userNotFound {
            let user = User(
                id: identity.uid,
                email: identity.email,
                name: identity.name,
                createdAt: .now,
                profile: nil,
                financialProfile: nil,
                behaviorProfile: nil,
                preferences: UserPreferences()
            )

            do {
                try dbService.createUser(user)
                session.setUser(user)
            } catch {
                try? authService.signOut()
                throw error
            }
        }
    }

    private func mapAppleError(_ error: Error) -> Error {
        if let appleError = error as? ASAuthorizationError{
         
            return appleError
        }

        return error
    }

    private func handleError(_ error: Error) {
        if let authError = error as? AuthError {
            if authError == .cancelled {
                clearMessages()
                return
            }
            lastAuthError = authError
            errorMessage = localizedAuthError(authError)
            return
        }

        lastAuthError = nil
        errorMessage = error.localizedDescription
    }

    private func localizedAuthError(_ authError: AuthError) -> String? {
        switch authError {
        case .invalidEmail:
            return localized("Please enter a valid email address.")
        case .wrongPassword:
            return localized("Incorrect password. Please try again.")
        case .invalidCredential:
            return localized("Incorrect credentials. Please try again.")
        case .userNotFound:
            return localized("No account found with this email.")
        case .emailAlreadyInUse:
            return localized("An account with this email already exists.")
        case .weakPassword:
            return localized("Password must be at least 8 characters.")
        case .emailNotVerified:
            return localized("Verify your email first. We sent a new verification link.")
        case .networkError:
            return localized("Network error. Please check your connection.")
        case .tooManyRequests:
            return localized("Too many attempts. Try again in a moment.")
        case .requiresRecentLogin:
            return localized("Please confirm your password before deleting your account.")
        case .noAuthenticatedUser:
            return localized("No active account session was found.")
        case .missingGoogleClientID:
            return localized("Google Sign-In is not configured. Download a fresh GoogleService-Info.plist and add its URL scheme.")
        case .missingIdentityToken:
            return localized("The identity provider did not return a valid sign-in token.")
        case .missingProviderEmail:
            return localized("The sign-in provider did not return an email address.")
        case .invalidAppleCredential:
            return localized("Apple Sign-In returned an invalid credential.")
        case .unableToPresentSocialSignIn:
            return localized("Unable to open the sign-in sheet right now. Please try again.")
        case .providerUnavailable(let message):
            return message
        case .cancelled:
            return nil
        case .unknown(let message):
            return message
        }
    }
}
