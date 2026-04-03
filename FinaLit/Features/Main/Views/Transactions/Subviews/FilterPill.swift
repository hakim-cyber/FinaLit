//
//  FilterPill.swift
//  FinaLit
//

import SwiftUI

struct FilterPill: View {
    let label: String
    let isActive: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(isActive ? .white : Color(hex: "4B5563"))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isActive ? Color(hex: "6366F1") : Color(hex: "111118"))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isActive ? Color.clear : Color(hex: "1F2937"), lineWidth: 1)
                )
        }
    }
}
