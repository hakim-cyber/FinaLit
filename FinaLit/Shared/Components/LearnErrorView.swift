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
            Text(L10n.Common.empty2)
                .font(.system(size: 36))
            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "F87171"))
                .multilineTextAlignment(.center)
            Button(L10n.Common.tryAgain) {
                Task { await retry() }
            }
            .font(.system(size: 14))
            .foregroundStyle(Color(hex: "6366F1"))
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }
}
