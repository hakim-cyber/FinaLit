//
//  FinaLitApp.swift
//  FinaLit
//
//  Created by aplle on 2/17/26.
//

import SwiftUI

import Firebase

@main
struct FinaLitApp: App {
    @State private var session        = UserSession()
    @State private var appCoordinator = AppCoordinator()
    @State private var authService    = AuthService()
    @State private var dbService      = DatabaseService()

    // ✅ Created here — dependencies are already @State so they exist immediately
    @State private var authViewModel: AuthViewModel
    @State private var onboardingViewModel: OnboardingViewModel

    init() {
        FirebaseApp.configure()
        let authService = AuthService()
        let dbService   = DatabaseService()
        let session     = UserSession()

        _authService    = State(initialValue: authService)
        _dbService      = State(initialValue: dbService)
        _session        = State(initialValue: session)
        _authViewModel  = State(initialValue: AuthViewModel(
            authService: authService,
            dbService: dbService,
            session: session
        ))
        _onboardingViewModel = State(initialValue: OnboardingViewModel(dbService: dbService, session: session))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
                .environment(appCoordinator)
                .environment(authService)
                .environment(dbService)
                .environment(authViewModel)
                .environment(onboardingViewModel)
                .task {
                    await restoreSession()
                }
        }
    }

    private func restoreSession() async {
        defer { session.finishSessionRestore() }

        guard let uid = authService.currentUID else { return }

        // Firebase says user is logged in — fetch their data
        if let user = try? await dbService.fetchUser(uid: uid) {
            session.setUser(user)
            // RootView reacts → skips auth, goes to onboarding or main
        }
    }
}
