//
//  AdminField.swift
//  FinaLit
//

import SwiftUI

struct AdminField: View {
    let label: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color(hex: "4B5563"))
            TextField(placeholder, text: $text)
                .font(.system(size: 15))
                .foregroundStyle(.white)
                .padding(12)
                .background(Color(hex: "111118"))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(hex: "1F2937"), lineWidth: 1)
                )
        }
    }
}
