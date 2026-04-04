//
//  MainLoadingView.swift
//  FinaLit
//

import SwiftUI

struct MainLoadingView: View {
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            ProgressView()
                .tint(AppTheme.accent)
                .scaleEffect(1.3)
        }
    }
}
