//
//  MainLoadingView.swift
//  FinaLit
//

import SwiftUI

struct MainLoadingView: View {
    var body: some View {
        ZStack {
            Color(hex: "0A0A0F").ignoresSafeArea()
            ProgressView()
                .tint(Color(hex: "6366F1"))
                .scaleEffect(1.3)
        }
    }
}
