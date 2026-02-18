//
//  RootTabView.swift
//  FinaLit
//
//  Created by aplle on 2/18/26.
//


// RootTabView.swift
// Core/Navigation/
// RootTabView.swift
// Core/Navigation/

import SwiftUI

struct RootTabView: View {
    @Environment(AppCoordinator.self) private var appCoordinator

    var body: some View {
        @Bindable var appCoordinator = appCoordinator

        TabView(selection: $appCoordinator.selectedTab) {

            // ── Tab 1: Main ────────────────────────────────────
            CoordinatorStack(MainPages.dashboard) { coordinator in
                appCoordinator.register(coordinator)    // hand coordinator to AppCoordinator
            }
            .tabItem { Label("Main", systemImage: "chart.pie.fill") }
            .tag(AppTab.main)

            // ── Tab 2: Chat ────────────────────────────────────
            CoordinatorStack(ChatPages.chat) { coordinator in
                appCoordinator.register(coordinator)
            }
            .tabItem { Label("AI Chat", systemImage: "brain.head.profile") }
            .tag(AppTab.chat)

            // ── Tab 3: Learn ───────────────────────────────────
            CoordinatorStack(LearnPages.home) { coordinator in
                appCoordinator.register(coordinator)
            }
            .tabItem { Label("Learn", systemImage: "book.fill") }
            .tag(AppTab.learn)
        }
        .tint(.blue)
    }
}

// ── Tab identifiers ────────────────────────────────────────────
enum AppTab {
    case main
    case chat
    case learn
}
