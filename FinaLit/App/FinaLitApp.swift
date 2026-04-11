//
//  FinaLitApp.swift
//  FinaLit
//
//  Created by aplle on 2/17/26.
//

import SwiftUI
import SwiftData
import Firebase
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

@main
struct FinaLitApp: App {

    @State private var session: UserSession
    @State private var appCoordinator: AppCoordinator
    @State private var authService: AuthService
    @State private var dbService: DatabaseService

    // ✅ Created here — dependencies are already @State so they exist immediately
    @State private var authViewModel: AuthViewModel
    @State private var onboardingViewModel: OnboardingViewModel
    @State private var learnViewModel: LearnViewModel
    @State private var adminViewModel: AdminViewModel
    @State private var mainViewModel: MainViewModel
    @State private var chatViewModel: ChatViewModel
    @State private var appPreferences: AppPreferencesStore

    init() {
        FirebaseApp.configure()
        AppTheme.configureAppearance()
        let authService = AuthService()
        let dbService = DatabaseService()
        let session = UserSession()
        let appCoordinator = AppCoordinator()

        _authService = State(initialValue: authService)
        _dbService = State(initialValue: dbService)
        _session = State(initialValue: session)
        _appCoordinator = State(initialValue: appCoordinator)
        _authViewModel = State(initialValue: AuthViewModel(
            authService: authService,
            dbService: dbService,
            session: session
        ))
        _onboardingViewModel = State(initialValue: OnboardingViewModel(dbService: dbService, session: session))
        _learnViewModel = State(initialValue: LearnViewModel(db: dbService, session: session))
        _adminViewModel  = State(initialValue: AdminViewModel(db: dbService, session: session))
        _mainViewModel = State(initialValue: MainViewModel(db: dbService, session: session))
        _chatViewModel = State(initialValue: ChatViewModel(session: session, repository: LocalChatRepository(), contextBuilder: ChatAdvisorContextBuilder(), memoryService: ChatConversationMemoryService(), aiService:GeminiAIChatService() ))
        _appPreferences = State(initialValue: AppPreferencesStore(dbService: dbService, session: session))
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
                .environment(learnViewModel)
                .environment(adminViewModel)
                .environment(mainViewModel)
                .environment(chatViewModel)
                .environment(appPreferences)
                .environment(\.locale, appPreferences.locale)
                .task {
                    await restoreSession()
                    appPreferences.refreshFromCurrentSession()
                }
                .onChange(of: session.user?.id) { _, _ in
                    appPreferences.handleSessionUserChanged()
                }
                .onOpenURL { url in
#if canImport(GoogleSignIn)
                    _ = GIDSignIn.sharedInstance.handle(url)
#endif
                }
        }
        .modelContainer(for: [ChatThreadEntity.self, ChatMessageEntity.self])
    }

    private func restoreSession() async {
        defer { session.finishSessionRestore() }

        guard let uid = authService.currentUID else { return }

        do {
            try await authService.reloadCurrentUser()
        } catch {
            try? authService.signOut()
            return
        }

        if authService.currentUserRequiresEmailVerification && !authService.isCurrentUserEmailVerified {
            try? authService.signOut()
            return
        }

        // Firebase says user is logged in — fetch their data
        if let user = try? await dbService.fetchUser(uid: uid) {
            session.setUser(user)
            // RootView reacts → skips auth, goes to onboarding or main
        }
    }
}
