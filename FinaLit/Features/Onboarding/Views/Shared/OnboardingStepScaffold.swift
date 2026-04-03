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
                            HStack {
                                if page.stepNumber > 1 {
                                    Button {
                                        coordinator.pop()
                                    } label: {
                                        Image(systemName: "chevron.left")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundStyle(.white)
                                            .frame(width: 34, height: 34)
                                            .background(OnboardingPalette.background.opacity(0.8), in: RoundedRectangle(cornerRadius: 10))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(OnboardingPalette.border, lineWidth: 1)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }

                                Spacer()

                                Text("STEP \(page.stepNumber) OF \(OnboardingPages.totalSteps)")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(OnboardingPalette.muted)
                            }

                            ProgressView(value: Double(page.stepNumber), total: Double(OnboardingPages.totalSteps))
                                .tint(OnboardingPalette.accent)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text(title)
                                .font(.system(size: 30, weight: .medium))
                                .foregroundStyle(.white)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(subtitle)
                                .font(.system(size: 13))
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
                                        .tint(.white)
                                }
                                Text(primaryTitle)
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .foregroundStyle((isPrimaryEnabled && !isLoading) ? .white : OnboardingPalette.disabledText)
                            .background(
                                LinearGradient(
                                    colors: (isPrimaryEnabled && !isLoading)
                                        ? [Color(hex: "6366F1"), Color(hex: "4F46E5")]
                                        : [OnboardingPalette.border, OnboardingPalette.border],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(!isPrimaryEnabled || isLoading)

                        Text("Educational guidance, not financial advice.")
                            .font(.system(size: 11))
                            .foregroundStyle(OnboardingPalette.muted)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(22)
                    .background(OnboardingPalette.surface, in: RoundedRectangle(cornerRadius: 24))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(OnboardingPalette.border, lineWidth: 1)
                    )
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
                .foregroundStyle(Color(hex: "F87171"))
            Text(message)
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: "FCA5A5"))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "450A0A").opacity(0.45), in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(hex: "7F1D1D"), lineWidth: 1)
        )
    }
}
