//
//  ProfileSettingsStatusBanner.swift
//  FinaLit
//

import SwiftUI

struct ProfileSettingsStatusBanner: View {
    enum Tone {
        case error
        case success
    }

    let message: String
    let tone: Tone

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: tone == .error ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .foregroundStyle(tone == .error ? Color(hex: "F87171") : Color(hex: "10B981"))
            Text(message)
                .font(.system(size: 12))
                .foregroundStyle(tone == .error ? Color(hex: "FCA5A5") : Color(hex: "6EE7B7"))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            (tone == .error ? Color(hex: "450A0A") : Color(hex: "052E16")).opacity(0.45),
            in: RoundedRectangle(cornerRadius: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(tone == .error ? Color(hex: "7F1D1D") : Color(hex: "166534"), lineWidth: 1)
        )
    }
}
