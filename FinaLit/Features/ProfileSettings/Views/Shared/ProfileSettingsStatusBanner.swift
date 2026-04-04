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
                .foregroundStyle(tone == .error ? AppTheme.danger : AppTheme.success)
            Text(message)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appSurface(tone == .error ? .tinted(.danger) : .tinted(.success), padding: 12, cornerRadius: AppTheme.CornerRadius.medium)
    }
}
