//
//  AnswerRow.swift
//  FinaLit
//

import SwiftUI

struct AnswerRow: View {
    let label: String
    let text: String
    let correct: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(correct ? Color(hex: "10B981") : Color(hex: "F87171"))
                .font(.system(size: 14))
            VStack(alignment: .leading, spacing: 2) {
                Text(label.uppercased())
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Color(hex: "4B5563"))
                Text(text)
                    .font(.system(size: 14))
                    .foregroundStyle(correct ? Color(hex: "10B981") : Color(hex: "F87171"))
            }
        }
    }
}
