//
//  AppNavigationCommand.swift
//  FinaLit
//
//  Created by aplle on 2/18/26.
//


// AppCoordinator.swift
// Core/Navigation/

import SwiftUI


enum AppNavigationCommand {
   
}

// ── AppCoordinator ─────────────────────────────────────────────────────────
// Lives ABOVE RootTabView. Owns selectedTab + fires commands down into tabs.
@Observable
class AppCoordinator {
    var selectedTab: AppTab = .learn

    // Each tab's coordinator is registered here when the tab appears
    // We use weak wrappers to avoid retain cycles
    private var mainCoordinator:  Coordinator<MainPages>?
    private var chatCoordinator:  Coordinator<ChatPages>?
    private var learnCoordinator: Coordinator<LearnPages>?

    // MARK: - Tab Registration
    // Called from each CoordinatorStack's .onAppear
    func register(_ coordinator: Coordinator<MainPages>)  { mainCoordinator  = coordinator }
    func register(_ coordinator: Coordinator<ChatPages>)  { chatCoordinator  = coordinator }
    func register(_ coordinator: Coordinator<LearnPages>) { learnCoordinator = coordinator }

    // MARK: - Navigate
    // Single entry point for ALL cross-tab navigation
    func navigate(to command: AppNavigationCommand) {
      
    }

    // MARK: - Private
    private func switchTab(to tab: AppTab) {
        guard selectedTab != tab else { return }
        selectedTab = tab
    }
}
