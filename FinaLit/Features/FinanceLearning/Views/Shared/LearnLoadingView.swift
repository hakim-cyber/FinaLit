//
//  LearnLoadingView.swift
//  FinaLit
//

import SwiftUI

struct LearnLoadingView: View {
    var body: some View {
        ZStack {
            Color(hex: "0A0A0F").opacity(0.8).ignoresSafeArea()
            ProgressView()
                .tint(Color(hex: "6366F1"))
                .scaleEffect(1.3)
        }
    }
}
