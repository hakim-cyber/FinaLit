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
    private(set) var lastAuthError: AuthError?

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

    // MARK: - Register
    func register() async {
        guard isRegisterFormValid else {
            if trimmedName.isEmpty {
                errorMessage = "Please enter your name."
            } else if !isEmailValid {
                errorMessage = "Please enter a valid email address."
            } else if password.count < 8 {
                errorMessage = "Password must be at least 8 characters."
            } else if password != confirmPassword {
                errorMessage = "Passwords do not match."
            } else {
                errorMessage = "Please fill in all fields."
            }
            return
        }

        isLoading    = true
        errorMessage = nil
        defer { isLoading = false }

        var createdUID: String?

        do {
            // 1. Create Firebase Auth account → get UID
            let uid = try await authService.register(email: trimmedEmail, password: password)
            createdUID = uid

            // 2. Build minimal User — profiles filled during onboarding
            let user = User(
                id: uid,
                email: trimmedEmail,
                name: trimmedName,
                createdAt: .now,
                profile: nil,
                financialProfile: nil,
                behaviorProfile: nil
            )

            // 3. Persist to Firestore
            try dbService.createUser(user)

            // 4. Set session → RootView reacts → shows onboarding
            session.setUser(user)

        } catch {
            if let createdUID, authService.currentUID == createdUID {
                // Roll back auth user if Firestore bootstrap fails.
                try? await authService.deleteCurrentUser()
                try? authService.signOut()
            }
            handleError(error)
        }
    }

    // MARK: - Login
    func login() async {
        guard isLoginFormValid else {
            errorMessage = "Please enter a valid email and password."
            return
        }

        isLoading    = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // 1. Firebase Auth → get UID
            let uid = try await authService.login(email: trimmedEmail, password: password)

            // 2. Fetch full User from Firestore
            //    This includes any saved profiles → hasCompletedOnboarding computed correctly
            let user: User
            do {
                user = try await dbService.fetchUser(uid: uid)
            } catch DBError.userNotFound {
                // Recover missing user doc to avoid broken sessions after partial failures.
                let fallbackName = trimmedName.isEmpty
                    ? (trimmedEmail.split(separator: "@").first.map(String.init) ?? "User")
                    : trimmedName
                let recoveredUser = User(
                    id: uid,
                    email: trimmedEmail,
                    name: fallbackName,
                    createdAt: .now
                )
                try dbService.createUser(recoveredUser)
                user = recoveredUser
            }

            // 3. Set session → RootView reacts
            //    If onboarding was done before  → goes to RootTabView
            //    If onboarding was not done yet → goes to OnboardingPages
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
            errorMessage = "Please enter your email address."
            return
        }

        isLoading      = true
        errorMessage   = nil
        successMessage = nil
        defer { isLoading = false }

        do {
            try await authService.sendPasswordReset(email: trimmedEmail)
            successMessage = "Password reset email sent. Check your inbox."
        } catch {
            handleError(error)
        }
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
            errorMessage = "Session expired. Please log in again."
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
            errorMessage = "Please enter your password."
            return false
        }

        guard let email = session.user?.email, !email.isEmpty else {
            errorMessage = "Email is unavailable for this account."
            return false
        }

        isLoading = true
        clearMessages()
        defer { isLoading = false }

        do {
            try await authService.reauthenticateCurrentUser(email: email, password: trimmedPassword)
            successMessage = "Identity confirmed."
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

    private func handleError(_ error: Error) {
        if let authError = error as? AuthError {
            lastAuthError = authError
            errorMessage = authError.errorDescription
            return
        }

        lastAuthError = nil
        errorMessage = error.localizedDescription
    }
}
