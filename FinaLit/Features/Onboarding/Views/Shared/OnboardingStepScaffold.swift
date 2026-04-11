//
//  OnboardingStepScaffold.swift
//  FinaLit
//

import SwiftUI

struct OnboardingStepScaffold<Content: View>: View {
    let page: OnboardingPages
    let title: String
    let subtitle: String
    let errorMessage: String?
    let isLoading: Bool
    let primaryTitle: String
    let isPrimaryEnabled: Bool
    let onPrimaryTap: () -> Void
    @ViewBuilder let content: () -> Content

    @Environment(Coordinator<OnboardingPages>.self) private var coordinator

    var body: some View {
        ZStack {
            OnboardingPalette.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(spacing: 14) {
                            ZStack {
                                Text("STEP \(page.stepNumber) OF \(OnboardingPages.totalSteps)")
                                    .font(AppTheme.Typography.badge)
                                    .foregroundStyle(OnboardingPalette.muted)
                                    .frame(maxWidth: .infinity)

                                HStack {
                                    if page.stepNumber > 1 {
                                        Button {
                                            coordinator.pop()
                                        } label: {
                                            Image(systemName: "chevron.left")
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundStyle(AppTheme.textPrimary)
                                                .frame(width: 34, height: 34)
                                                .background(OnboardingPalette.surface, in: RoundedRectangle(cornerRadius: 10))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .stroke(OnboardingPalette.border, lineWidth: 1)
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }

                                    Spacer()
                                }
                            }

                            ProgressView(value: Double(page.stepNumber), total: Double(OnboardingPages.totalSteps))
                                .tint(OnboardingPalette.accent)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text(title)
                                .font(.system(size: 30, weight: .medium))
                                .foregroundStyle(AppTheme.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(subtitle)
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(OnboardingPalette.muted)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        if let errorMessage, !errorMessage.isEmpty {
                            AuthErrorBanner(message: errorMessage)
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

                        Text("Educational guidance, not financial advice.")
                            .font(.system(size: 11))
                            .foregroundStyle(OnboardingPalette.muted)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .appSurface(.primary, padding: 22, cornerRadius: 24)
                    .frame(maxWidth: 640)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 28)
                }
            }
        }
    }
}

private struct AuthErrorBanner: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(AppTheme.danger)
            Text(message)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appSurface(.tinted(.danger), padding: 12, cornerRadius: AppTheme.CornerRadius.medium)
    }
}
