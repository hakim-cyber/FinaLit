//
//  ProgressStatCard.swift
//  FinaLit
//

import SwiftUI

struct ProgressStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color(hex: color))
                .font(.system(size: 18))
            VStack(alignment: .leading, spacing: 3) {
                Text(value)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.white)
                Text(label)
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "4B5563"))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "111118"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(hex: "1F2937"), lineWidth: 1)
        )
    }
}
