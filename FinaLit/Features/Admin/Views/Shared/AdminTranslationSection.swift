//
//  AdminTranslationSection.swift
//  FinaLit
//

import SwiftUI

struct AdminTranslationSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color(hex: "4B5563"))

            VStack(spacing: 12) {
                content()
            }
            .padding(14)
            .background(Color(hex: "111118"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "1F2937"), lineWidth: 1)
            )
        }
    }
}
