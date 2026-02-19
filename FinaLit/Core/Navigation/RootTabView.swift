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
    @Environment(UserSession.self) private var session
    
    var body: some View {
        @Bindable var appCoordinator = appCoordinator

        TabView(selection: $appCoordinator.selectedTab) {
           
            CoordinatorStack(LearnPages.home) { coordinator in
                appCoordinator.register(coordinator)
            }
            .tabItem { Label("Learn", systemImage: "book.fill") }
            .tag(AppTab.learn)
          
            
            CoordinatorStack(MainPages.dashboard) { coordinator in
                appCoordinator.register(coordinator)    // hand coordinator to AppCoordinator
            }
            .tabItem { Label("Main", systemImage: "chart.pie.fill") }
            .tag(AppTab.main)

         
            CoordinatorStack(ChatPages.chat) { coordinator in
                appCoordinator.register(coordinator)
            }
            .tabItem { Label("AI Chat", systemImage: "brain.head.profile") }
            .tag(AppTab.chat)

            // RootTabView.swift
            if session.user?.isAdmin == true {
                CoordinatorStack(AdminPages.home)
                    .tabItem { Label("Admin", systemImage: "gearshape.fill") }
                    .tag(AppTab.admin)
            }
        }
        .tint(.blue)
    }
}

// ── Tab identifiers ────────────────────────────────────────────
enum AppTab {
    case main
    case chat
    case learn
    case admin
}
