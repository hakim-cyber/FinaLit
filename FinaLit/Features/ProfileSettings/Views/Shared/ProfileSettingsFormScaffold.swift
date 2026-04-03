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
                                .foregroundStyle(.white)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(subtitle)
                                .font(.system(size: 13))
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
                                        .tint(.white)
                                }
                                Text(primaryTitle)
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .foregroundStyle((isPrimaryEnabled && !isLoading) ? .white : ProfileSettingsPalette.disabledText)
                            .background(
                                LinearGradient(
                                    colors: (isPrimaryEnabled && !isLoading)
                                        ? [Color(hex: "6366F1"), Color(hex: "4F46E5")]
                                        : [ProfileSettingsPalette.border, ProfileSettingsPalette.border],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(!isPrimaryEnabled || isLoading)
                    }
                    .padding(22)
                    .background(ProfileSettingsPalette.surface, in: RoundedRectangle(cornerRadius: 24))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(ProfileSettingsPalette.border, lineWidth: 1)
                    )
                    .frame(maxWidth: 680)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }
        }
    }
}
