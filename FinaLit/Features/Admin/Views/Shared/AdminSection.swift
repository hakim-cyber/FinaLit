//
//  AdminSection.swift
//  FinaLit
//

import SwiftUI

struct AdminSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color(hex: "4B5563"))
                .padding(.horizontal, 20)
            VStack(spacing: 1) { content }
                .background(Color(hex: "111118"))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 20)
        }
    }
}
