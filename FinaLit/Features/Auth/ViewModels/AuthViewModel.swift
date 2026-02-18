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
    var isLoginFormValid: Bool {
        !email.isEmpty && !password.isEmpty
    }

    var isRegisterFormValid: Bool {
        !name.isEmpty &&
        !email.isEmpty &&
        password.count >= 6 &&
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
            errorMessage = password != confirmPassword
                ? "Passwords do not match."
                : "Please fill in all fields."
            return
        }

        isLoading    = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // 1. Create Firebase Auth account → get UID
            let uid = try await authService.register(email: email, password: password)

            // 2. Build minimal User — profiles filled during onboarding
            let user = User(
                id: uid,
                email: email,
                name: name.trimmingCharacters(in: .whitespaces),
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
            errorMessage = "Please enter your email and password."
            return
        }

        isLoading    = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // 1. Firebase Auth → get UID
            let uid = try await authService.login(email: email, password: password)

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