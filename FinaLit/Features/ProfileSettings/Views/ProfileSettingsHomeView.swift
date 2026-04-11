//
//  ProfileSettingsHomeView.swift
//  FinaLit
//
//  Created by Codex on 2/21/26.
//

import SwiftUI

struct ProfileSettingsHomeView: View {
    @Environment(UserSession.self) private var session
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(AppPreferencesStore.self) private var preferences
    @Environment(Coordinator<SettingsPages>.self) private var coordinator
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var showSignOutConfirmation = false
    @State private var showDeleteConfirmation = false
    @State private var showDeleteFinalConfirmation = false
    @State private var showReauthSheet = false

    @State private var isSendingPasswordReset = false
    @State private var isDeletingAccount = false
    @State private var isReauthenticating = false

    @State private var feedbackTitle = ""
    @State private var feedbackMessage = ""
    @State private var showFeedback = false
    @State private var reauthPassword = ""

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
        return "v\(version) (\(build))"
    }

    private func localized(_ key: String, _ arguments: CVarArg...) -> String {
        L10n.tr(key, language: preferences.appLanguage, arguments: arguments)
    }

    var body: some View {
        ZStack {
            ProfileSettingsPalette.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    SettingsSectionCard(title: "PROFILE") {
                        SettingsActionRow(
                            title: "Personal Info",
                            subtitle: "Name, age, country, employment",
                            icon: "person.text.rectangle.fill",
                            action: { coordinator.push(.personalInfo) }
                        )

                        Divider()
                            .overlay(ProfileSettingsPalette.border)

                        SettingsActionRow(
                            title: "Financial Profile",
                            subtitle: "Income, expenses, savings, debt, risk",
                            icon: "chart.line.uptrend.xyaxis",
                            action: { coordinator.push(.financialProfile) }
                        )

                        Divider()
                            .overlay(ProfileSettingsPalette.border)

                        SettingsActionRow(
                            title: "Goals",
                            subtitle: "Narrative short and long-term goals",
                            icon: "target",
                            action: { coordinator.push(.goals) }
                        )
                    }

                    SettingsSectionCard(title: "LANGUAGE") {
                        SettingsLanguageMenuRow(
                            title: "App Language",
                            subtitle: "Changes labels, alerts, onboarding, and assistant defaults",
                            value: preferences.appLanguage.nativeDisplayName,
                            icon: "globe",
                            options: AppLanguage.allCases.map { ($0.nativeDisplayName, $0.rawValue) }
                        ) { selectedValue in
                            guard let language = AppLanguage(rawValue: selectedValue) else { return }
                            preferences.setAppLanguage(language)
                        }

                        Divider()
                            .overlay(ProfileSettingsPalette.border)

                        SettingsLanguageMenuRow(
                            title: "Learning Content",
                            subtitle: "Lesson, quiz, week, and tip language",
                            value: learningContentLabel,
                            icon: "book.closed.fill",
                            options: learningOptions
                        ) { selectedValue in
                            if selectedValue == "followApp" {
                                preferences.setLearningLanguagePreference(.followApp)
                            } else if let language = AppLanguage(rawValue: selectedValue) {
                                preferences.setLearningLanguagePreference(.specific(language))
                            }
                        }
                    }

                    SettingsSectionCard(title: "APP & ACCOUNT") {
                        SettingsValueRow(
                            title: "App Version",
                            subtitle: "Build information",
                            value: appVersion,
                            icon: "info.circle.fill"
                        )

                        Divider()
                            .overlay(ProfileSettingsPalette.border)

                        SettingsActionRow(
                            title: "Forgot Password",
                            subtitle: "Send reset link to \(session.user?.email ?? "your email")",
                            icon: "key.fill",
                            isLoading: isSendingPasswordReset,
                            action: sendPasswordReset
                        )

                        Divider()
                            .overlay(ProfileSettingsPalette.border)

                        SettingsActionRow(
                            title: "Privacy Policy",
                            subtitle: "How your data is used and protected",
                            icon: "hand.raised.fill",
                            action: { openLegalLink(AppLegalLinks.privacyPolicyURL, name: "Privacy Policy") }
                        )

                        Divider()
                            .overlay(ProfileSettingsPalette.border)

                        SettingsActionRow(
                            title: "Terms of Use",
                            subtitle: "Rules and conditions for using FinaLit",
                            icon: "doc.text.fill",
                            action: { openLegalLink(AppLegalLinks.termsOfUseURL, name: "Terms of Use") }
                        )
                    }

                    SettingsSectionCard(title: "SECURITY") {
                        SettingsActionRow(
                            title: "Sign Out",
                            subtitle: "Log out on this device",
                            icon: "rectangle.portrait.and.arrow.right",
                            action: { showSignOutConfirmation = true }
                        )

                        Divider()
                            .overlay(ProfileSettingsPalette.border)

                        SettingsActionRow(
                            title: "Delete Account",
                            subtitle: "Permanently remove account and app data",
                            icon: "trash.fill",
                            isLoading: isDeletingAccount,
                            isDestructive: true,
                            action: { showDeleteConfirmation = true }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 36)
            }
        }
        .navigationTitle("Profile Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    dismiss()
                }
                .font(.system(size: 13, weight: .semibold))
            }
        }
        .alert("Sign out?", isPresented: $showSignOutConfirmation) {
            Button("Sign Out", role: .destructive) {
                authViewModel.signOut()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You can log back in anytime with your email and password.")
        }
        .alert("Delete account?", isPresented: $showDeleteConfirmation) {
            Button("Continue", role: .destructive) {
                showDeleteFinalConfirmation = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action is permanent and cannot be undone.")
        }
        .alert("Final confirmation", isPresented: $showDeleteFinalConfirmation) {
            Button("Delete Forever", role: .destructive) {
                deleteAccount()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All account data will be permanently removed.")
        }
        .alert(feedbackTitle, isPresented: $showFeedback) {
            Button("OK", role: .cancel) {
                authViewModel.clearMessages()
            }
        } message: {
            Text(feedbackMessage)
        }
        .sheet(isPresented: $showReauthSheet) {
            reauthSheet
        }
    }

    private func sendPasswordReset() {
        guard let email = session.user?.email, !email.isEmpty else {
            presentFeedback(
                title: localized("Reset unavailable"),
                message: localized("No email address is available for this account.")
            )
            return
        }

        isSendingPasswordReset = true

        Task { @MainActor in
            await authViewModel.sendPasswordReset(to: email)
            isSendingPasswordReset = false

            if let error = authViewModel.errorMessage, !error.isEmpty {
                presentFeedback(title: localized("Reset failed"), message: error)
                return
            }

            presentFeedback(
                title: localized("Reset email sent"),
                message: authViewModel.successMessage ?? localized("Check your inbox for reset instructions.")
            )
        }
    }

    private func deleteAccount() {
        isDeletingAccount = true

        Task { @MainActor in
            await authViewModel.deleteAccount()
            isDeletingAccount = false

            if let error = authViewModel.errorMessage, !error.isEmpty {
                if authViewModel.needsReauthenticationForDeletion {
                    reauthPassword = ""
                    showReauthSheet = true
                    return
                }
                presentFeedback(title: localized("Delete failed"), message: error)
                return
            }

            dismiss()
        }
    }

    private func confirmReauthenticationAndDelete() {
        isReauthenticating = true

        Task { @MainActor in
            let isVerified = await authViewModel.reauthenticateForAccountDeletion(password: reauthPassword)
            isReauthenticating = false

            guard isVerified else {
                presentFeedback(
                    title: localized("Verification failed"),
                    message: authViewModel.errorMessage ?? localized("Please try again.")
                )
                return
            }

            showReauthSheet = false
            reauthPassword = ""
            deleteAccount()
        }
    }

    private func openLegalLink(_ url: URL?, name: String) {
        guard let url else {
            presentFeedback(
                title: localized("%@ unavailable", name),
                message: localized("Link is not configured.")
            )
            return
        }

        openURL(url) { accepted in
            if !accepted {
                Task { @MainActor in
                    presentFeedback(
                        title: localized("%@ unavailable", name),
                        message: localized("Unable to open this link right now.")
                    )
                }
            }
        }
    }

    private func presentFeedback(title: String, message: String) {
        feedbackTitle = title
        feedbackMessage = message
        showFeedback = true
    }

    private var learningOptions: [(String, String)] {
        [(L10n.tr("Follow App", language: preferences.appLanguage), "followApp")]
            + AppLanguage.allCases.map { ($0.nativeDisplayName, $0.rawValue) }
    }

    private var learningContentLabel: String {
        switch preferences.learningLanguagePreference {
        case .followApp:
            return L10n.tr(
                "Follow App (%@)",
                language: preferences.appLanguage,
                preferences.appLanguage.nativeDisplayName
            )
        case .specific(let language):
            return language.nativeDisplayName
        }
    }

    private var reauthSheet: some View {
        NavigationStack {
            ZStack {
                ProfileSettingsPalette.background.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 14) {
                    Text("For security, confirm your password to continue account deletion.")
                        .font(.system(size: 13))
                        .foregroundStyle(ProfileSettingsPalette.muted)

                    SecureField("Current password", text: $reauthPassword)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .settingsInputStyle()

                    Button(action: confirmReauthenticationAndDelete) {
                        HStack(spacing: 10) {
                            if isReauthenticating {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(AppTheme.inverseText)
                            }
                            Text(isReauthenticating ? localized("Verifying...") : localized("Verify & Delete"))
                        }
                    }
                    .buttonStyle(AppFilledButtonStyle(tone: .danger))
                    .disabled(isReauthenticating || reauthPassword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(20)
            }
            .navigationTitle("Confirm Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        showReauthSheet = false
                        reauthPassword = ""
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(ProfileSettingsPalette.muted)
                }
            }
            .keyboardDoneToolbar()
        }
        .presentationDetents([.height(300)])
        .presentationDragIndicator(.visible)
    }
}

private struct SettingsSectionCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(ProfileSettingsPalette.muted)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                content()
            }
            .background(ProfileSettingsPalette.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(ProfileSettingsPalette.border, lineWidth: 1)
            )
        }
    }
}

private struct SettingsActionRow: View {
    let title: String
    let subtitle: String
    let icon: String
    var iconTint: Color = ProfileSettingsPalette.accent
    var isLoading: Bool = false
    var isDestructive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            SettingsRowShell(
                title: title,
                subtitle: subtitle,
                icon: icon,
                iconTint: isDestructive ? AppTheme.danger : iconTint,
                titleTint: isDestructive ? AppTheme.danger : AppTheme.textPrimary
            ) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(AppTheme.accent)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(ProfileSettingsPalette.muted)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}

private struct SettingsValueRow: View {
    let title: String
    let subtitle: String
    let value: String
    let icon: String

    var body: some View {
        SettingsRowShell(
            title: title,
            subtitle: subtitle,
            icon: icon,
            iconTint: AppTheme.textSecondary
        ) {
            Text(value)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppTheme.textSecondary)
        }
    }
}

private struct SettingsLanguageMenuRow: View {
    let title: String
    let subtitle: String
    let value: String
    let icon: String
    let options: [(label: String, value: String)]
    let onSelect: (String) -> Void

    var body: some View {
        Menu {
            ForEach(options, id: \.value) { option in
                Button(option.label) {
                    onSelect(option.value)
                }
            }
        } label: {
            SettingsRowShell(
                title: title,
                subtitle: subtitle,
                icon: icon,
                iconTint: AppTheme.accent
            ) {
                HStack(spacing: 8) {
                    Text(value)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(ProfileSettingsPalette.muted)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

private struct SettingsRowShell<Accessory: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconTint: Color
    var titleTint: Color = AppTheme.textPrimary
    @ViewBuilder let accessory: () -> Accessory

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconTint.opacity(0.16))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(iconTint)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15))
                    .foregroundStyle(titleTint)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(ProfileSettingsPalette.muted)
                    .lineLimit(1)
            }

            Spacer()
            accessory()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}
