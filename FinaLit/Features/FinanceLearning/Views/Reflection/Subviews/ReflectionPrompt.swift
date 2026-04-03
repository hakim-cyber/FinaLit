//
//  ReflectionPrompt.swift
//  FinaLit
//

import SwiftUI

struct ReflectionPrompt: View {
    let number: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color(hex: "6366F1"))
                .padding(.top, 2)
            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "9CA3AF"))
                .lineSpacing(3)
        }
        .padding(14)
        .background(Color(hex: "111118"))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
