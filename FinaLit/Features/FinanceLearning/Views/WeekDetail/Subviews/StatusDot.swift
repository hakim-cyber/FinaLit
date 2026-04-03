//
//  StatusDot.swift
//  FinaLit
//

import SwiftUI

struct StatusDot: View {
    let done: Bool
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(done ? Color(hex: "10B981") : Color(hex: "374151"))
                .frame(width: 5, height: 5)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(done ? Color(hex: "10B981") : Color(hex: "4B5563"))
        }
    }
}
