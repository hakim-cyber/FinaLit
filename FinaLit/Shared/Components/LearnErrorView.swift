//
//  LearnErrorView.swift
//  FinaLit
//

import SwiftUI

struct LearnErrorView: View {
    let message: String
    let retry: () async -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("⚠️")
                .font(.system(size: 36))
            Text(message)
                .font(.system(size: 14, design: .monospaced))
                .foregroundStyle(Color(hex: "F87171"))
                .multilineTextAlignment(.center)
            Button("Try again") {
                Task { await retry() }
            }
            .font(.system(size: 14, design: .monospaced))
            .foregroundStyle(Color(hex: "6366F1"))
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }
}
