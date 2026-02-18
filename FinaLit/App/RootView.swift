//
//  RootView 2.swift
//  FinaLit
//
//  Created by aplle on 2/18/26.
//


// RootView.swift
// App/

import SwiftUI

struct RootView: View {
    @Environment(UserSession.self) private var session

    var body: some View {
        Group {
            if !session.isAuthenticated {
                // ── Auth Flow ──────────────────────────────────
                CoordinatorStack(AuthPages.login)

            } else if !session.hasCompletedOnboarding {
                // ── Onboarding Flow ────────────────────────────
                CoordinatorStack(OnboardingPages.personalInfo)

            } else {
                // ── Main App ───────────────────────────────────
                RootTabView()
            }
        }
        // Animate the switch between flows
        .animation(.easeInOut(duration: 0.3), value: session.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: session.hasCompletedOnboarding)
    }
}