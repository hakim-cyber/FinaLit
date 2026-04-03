//
//  AdminCreatedIDCard.swift
//  FinaLit
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct AdminCreatedIDCard: View {
    let title: String
    let value: String
    let hint: String
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color(hex: "4B5563"))

            Text(value)
                .font(.system(size: 13))
                .foregroundStyle(.white)
                .textSelection(.enabled)

            HStack(spacing: 10) {
                Button {
                    #if canImport(UIKit)
                    UIPasteboard.general.string = value
                    #endif
                    copied = true
                } label: {
                    Label(copied ? "Copied" : "Copy ID", systemImage: copied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: copied ? "10B981" : "6366F1"))
                }

                Text(hint)
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "4B5563"))
            }
        }
        .padding(14)
        .background(Color(hex: "111118"))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(hex: "1F2937"), lineWidth: 1)
        )
    }
}
