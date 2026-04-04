//
//  ProfileSettingsFormScaffold.swift
//  FinaLit
//

import SwiftUI

struct ProfileSettingsFormScaffold<Content: View>: View {
    let title: String
    let subtitle: String
    let errorMessage: String?
    let successMessage: String?
    let isLoading: Bool
    let primaryTitle: String
    let isPrimaryEnabled: Bool
    let onPrimaryTap: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            ProfileSettingsPalette.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(title)
                                .font(.system(size: 30, weight: .medium))
                                .foregroundStyle(AppTheme.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(subtitle)
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(ProfileSettingsPalette.muted)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        if let errorMessage, !errorMessage.isEmpty {
                            ProfileSettingsStatusBanner(message: errorMessage, tone: .error)
                        }

                        if let successMessage, !successMessage.isEmpty {
                            ProfileSettingsStatusBanner(message: successMessage, tone: .success)
                        }

                        content()

                        Button(action: onPrimaryTap) {
                            HStack(spacing: 10) {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .tint(AppTheme.inverseText)
                                }
                                Text(primaryTitle)
                            }
                        }
                        .buttonStyle(AppFilledButtonStyle(tone: .accent))
                        .disabled(!isPrimaryEnabled || isLoading)
                    }
                    .appSurface(.primary, padding: 22, cornerRadius: 24)
                    .frame(maxWidth: 680)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }
        }
    }
}
