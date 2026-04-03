//
//  ProfileSettingsButton.swift
//  FinaLit
//

import SwiftUI

struct ProfileSettingsButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(ProfileSettingsPalette.surface, in: RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(ProfileSettingsPalette.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
