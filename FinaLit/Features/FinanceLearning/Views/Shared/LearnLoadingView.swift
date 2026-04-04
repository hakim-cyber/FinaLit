//
//  LearnLoadingView.swift
//  FinaLit
//

import SwiftUI

struct LearnLoadingView: View {
    var body: some View {
        ZStack {
            AppTheme.background.opacity(0.8).ignoresSafeArea()
            ProgressView()
                .tint(AppTheme.accent)
                .scaleEffect(1.3)
        }
    }
}
