//
//  AdminToggle.swift
//  FinaLit
//

import SwiftUI

struct AdminToggle: View {
    let label: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color(hex: "4B5563"))
            Spacer()
            Toggle("", isOn: $isOn)
                .tint(Color(hex: "6366F1"))
        }
    }
}
