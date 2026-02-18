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

        do {
            // 1. Create Firebase Auth account → get UID
            let uid = try await authService.register(email: trimmedEmail, password: password)

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
            try await dbService.createUser(user)

            // 4. Set session → RootView reacts → shows onboarding
            session.setUser(user)

        } catch {
            errorMessage = error.localizedDescription
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
            let user = try await dbService.fetchUser(uid: uid)

            // 3. Set session → RootView reacts
            //    If onboarding was done before  → goes to RootTabView
            //    If onboarding was not done yet → goes to OnboardingPages
            session.setUser(user)

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Forgot Password
    func sendPasswordReset() async {
        guard !email.isEmpty else {
            errorMessage = "Please enter your email address."
            return
        }

        isLoading      = true
        errorMessage   = nil
        successMessage = nil
        defer { isLoading = false }

        do {
            try await authService.sendPasswordReset(email: email)
            successMessage = "Password reset email sent. Check your inbox."
        } catch {
            errorMessage = error.localizedDescription
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
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Helpers
    func clearError() {
        errorMessage = nil
    }

    private func clearForm() {
        name            = ""
        email           = ""
        password        = ""
        confirmPassword = ""
        errorMessage    = nil
        successMessage  = nil
    }
}
