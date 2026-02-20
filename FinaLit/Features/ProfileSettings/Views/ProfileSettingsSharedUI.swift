//
//  ProfileSettingsSharedUI.swift
//  FinaLit
//
//  Created by Codex on 2/21/26.
//

import SwiftUI

enum ProfileSettingsPalette {
    static let background = Color(hex: "0A0A0F")
    static let surface = Color(hex: "111118")
    static let border = Color(hex: "1F2937")
    static let muted = Color(hex: "6B7280")
    static let accent = Color(hex: "6366F1")
    static let disabledText = Color(hex: "4B5563")
}

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
                                .font(.system(size: 30, weight: .light, design: .serif))
                                .foregroundStyle(.white)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(subtitle)
                                .font(.system(size: 13, design: .monospaced))
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
                                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
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

struct ProfileSettingsTogglePill: View {
    let title: String
    let isSelected: Bool
    let tint: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(isSelected ? Color.white : ProfileSettingsPalette.muted)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(
                    RoundedRectangle(cornerRadius: 11)
                        .fill(isSelected ? tint.opacity(0.2) : ProfileSettingsPalette.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 11)
                        .stroke(isSelected ? tint : ProfileSettingsPalette.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct ProfileSettingsSelectableRow: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let accent: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Circle()
                    .fill(accent.opacity(isSelected ? 1 : 0.35))
                    .frame(width: 10, height: 10)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium, design: .serif))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(ProfileSettingsPalette.muted)
                        .lineLimit(2)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(accent)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? accent.opacity(0.14) : ProfileSettingsPalette.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? accent : ProfileSettingsPalette.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct ProfileSettingsStatusBanner: View {
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
                .font(.system(size: 12, design: .monospaced))
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

private struct ProfileSettingsInputFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 15, design: .serif))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .frame(height: 50)
            .background(ProfileSettingsPalette.background.opacity(0.8), in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(ProfileSettingsPalette.border, lineWidth: 1)
            )
    }
}

private struct ProfileSettingsTextAreaModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 15, design: .serif))
            .foregroundStyle(.white)
            .padding(14)
            .background(ProfileSettingsPalette.background.opacity(0.8), in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(ProfileSettingsPalette.border, lineWidth: 1)
            )
    }
}

extension View {
    func settingsInputStyle() -> some View {
        modifier(ProfileSettingsInputFieldModifier())
    }

    func settingsTextAreaStyle() -> some View {
        modifier(ProfileSettingsTextAreaModifier())
    }

    func settingsFieldLabelStyle() -> some View {
        font(.system(size: 11, weight: .semibold, design: .monospaced))
            .foregroundStyle(ProfileSettingsPalette.muted)
    }
}

func settingsTrimmed(_ value: String) -> String {
    value.trimmingCharacters(in: .whitespacesAndNewlines)
}

func settingsEditableAmount(_ value: Double) -> String {
    value == 0 ? "" : formatAmount(value)
}

func fallbackUserProfile(from user: User?) -> UserProfile {
    UserProfile(
        name: user?.profile?.name ?? user?.name ?? "",
        age: user?.profile?.age ?? 22,
        country: user?.profile?.country ?? AppRegion.defaultCountry,
        employmentStatus: user?.profile?.employmentStatus ?? .employed,
        monthlyIncome: user?.profile?.monthlyIncome ?? 0,
        incomeStability: user?.profile?.incomeStability ?? .stable
    )
}

func fallbackFinancialProfile(from user: User?) -> FinancialProfile {
    FinancialProfile(
        monthlyFixedExpenses: user?.financialProfile?.monthlyFixedExpenses ?? 0,
        monthlyVariableExpenses: user?.financialProfile?.monthlyVariableExpenses ?? 0,
        currentSavings: user?.financialProfile?.currentSavings ?? 0,
        hasDebt: user?.financialProfile?.hasDebt ?? false,
        debtAmount: user?.financialProfile?.debtAmount,
        emergencyFundMonths: user?.financialProfile?.emergencyFundMonths ?? 0,
        riskTolerance: user?.financialProfile?.riskTolerance ?? .medium,
        shortTermGoal: user?.financialProfile?.shortTermGoal ?? "",
        longTermGoal: user?.financialProfile?.longTermGoal ?? "",
        interestedInInvesting: user?.financialProfile?.interestedInInvesting ?? false,
        knowledgeLevel: user?.financialProfile?.knowledgeLevel ?? .beginner
    )
}
