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
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? String(localized: "profile.unknown")
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
        return "v\(version) (\(build))"
    }

    private func localized(_ text: String, _ arguments: CVarArg...) -> String {
        guard !arguments.isEmpty else { return text }
        return String(format: text, locale: Locale(identifier: "en_US_POSIX"), arguments: arguments)
    }

    var body: some View {
        ZStack {
            ProfileSettingsPalette.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    SettingsSectionCard(title: String(localized: "profile.profileSection")) {
                        SettingsActionRow(
                            title: String(localized: "profile.personalInfoTitle"),
                            subtitle: String(localized: "profile.personalInfoSub"),
                            icon: "person.text.rectangle.fill",
                            action: { coordinator.push(.personalInfo) }
                        )

                        Divider()
                            .overlay(ProfileSettingsPalette.border)

                        SettingsActionRow(
                            title: String(localized: "profile.financialProfile"),
                            subtitle: String(localized: "profile.financialProfileSub"),
                            icon: "chart.line.uptrend.xyaxis",
                            action: { coordinator.push(.financialProfile) }
                        )

                        Divider()
                            .overlay(ProfileSettingsPalette.border)

                        SettingsActionRow(
                            title: String(localized: "profile.goalsTitle"),
                            subtitle: String(localized: "profile.goalsSub"),
                            icon: "target",
                            action: { coordinator.push(.goals) }
                        )
                    }

                    SettingsSectionCard(title: String(localized: "profile.learningSection")) {
                        SettingsLanguageMenuRow(
                            title: String(localized: "profile.contentLanguage"),
                            subtitle: String(localized: "profile.learningLanguageSub"),
                            value: learningContentLabel,
                            icon: "globe",
                            options: learningOptions
                        ) { selectedValue in
                            if let language = AppLanguage(rawValue: selectedValue) {
                                preferences.setLearningLanguage(language)
                            }
                        }
                    }

                    SettingsSectionCard(title: String(localized: "profile.appAndAccountSection")) {
                        SettingsValueRow(
                            title: String(localized: "profile.appVersionTitle"),
                            subtitle: String(localized: "profile.appVersionSub"),
                            value: appVersion,
                            icon: "info.circle.fill"
                        )

                        Divider()
                            .overlay(ProfileSettingsPalette.border)

                        SettingsActionRow(
                            title: String(localized: "profile.forgotPasswordTitle"),
                            subtitle: "\(String(localized: "profile.sendResetLinkTo")) \(session.user?.email ?? String(localized: "profile.yourEmail"))",
                            icon: "key.fill",
                            isLoading: isSendingPasswordReset,
                            action: sendPasswordReset
                        )

                        Divider()
                            .overlay(ProfileSettingsPalette.border)

                        SettingsActionRow(
                            title: String(localized: "profile.privacyPolicy"),
                            subtitle: String(localized: "profile.privacyPolicySub"),
                            icon: "hand.raised.fill",
                            action: { openLegalLink(AppLegalLinks.privacyPolicyURL, name: String(localized: "profile.privacyPolicy")) }
                        )

                        Divider()
                            .overlay(ProfileSettingsPalette.border)

                        SettingsActionRow(
                            title: String(localized: "profile.termsOfUse"),
                            subtitle: String(localized: "profile.termsOfUseSub"),
                            icon: "doc.text.fill",
                            action: { openLegalLink(AppLegalLinks.termsOfUseURL, name: String(localized: "profile.termsOfUse")) }
                        )
                    }

                    SettingsSectionCard(title: String(localized: "profile.securitySection")) {
                        SettingsActionRow(
                            title: String(localized: "profile.signOutTitle"),
                            subtitle: String(localized: "profile.signOutSub"),
                            icon: "rectangle.portrait.and.arrow.right",
                            action: { showSignOutConfirmation = true }
                        )

                        Divider()
                            .overlay(ProfileSettingsPalette.border)

                        SettingsActionRow(
                            title: String(localized: "profile.deleteAccount"),
                            subtitle: String(localized: "profile.deleteAccountSub"),
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
        .navigationTitle(L10n.Profile.profileSettings)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(L10n.Common.done) {
                    dismiss()
                }
                .font(.system(size: 13, weight: .semibold))
            }
        }
        .alert(L10n.Profile.signOut2, isPresented: $showSignOutConfirmation) {
            Button(L10n.Profile.signOut, role: .destructive) {
                authViewModel.signOut()
                dismiss()
            }
            Button(L10n.Profile.cancel, role: .cancel) {}
        } message: {
            Text(L10n.Profile.youCanLogBackInAnytimeWithYourEmailAndPassword)
        }
        .alert(L10n.Profile.deleteAccount, isPresented: $showDeleteConfirmation) {
            Button(L10n.Profile.continueAction, role: .destructive) {
                showDeleteFinalConfirmation = true
            }
            Button(L10n.Profile.cancel, role: .cancel) {}
        } message: {
            Text(L10n.Profile.thisActionIsPermanentAndCannotBeUndone)
        }
        .alert(L10n.Profile.finalConfirmation, isPresented: $showDeleteFinalConfirmation) {
            Button(L10n.Profile.deleteForever, role: .destructive) {
                deleteAccount()
            }
            Button(L10n.Profile.cancel, role: .cancel) {}
        } message: {
            Text(L10n.Profile.allAccountDataWillBePermanentlyRemoved)
        }
        .alert(feedbackTitle, isPresented: $showFeedback) {
            Button(L10n.Auth.ok, role: .cancel) {
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
                title: String(localized: "profile.resetUnavailable"),
                message: String(localized: "profile.noEmailAccount")
            )
            return
        }

        isSendingPasswordReset = true

        Task { @MainActor in
            await authViewModel.sendPasswordReset(to: email)
            isSendingPasswordReset = false

            if let error = authViewModel.errorMessage, !error.isEmpty {
                presentFeedback(title: String(localized: "profile.resetFailed"), message: error)
                return
            }

            presentFeedback(
                title: String(localized: "profile.resetEmailSent"),
                message: authViewModel.successMessage ?? String(localized: "profile.checkInbox")
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
                presentFeedback(title: String(localized: "profile.deleteFailed"), message: error)
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
                    title: String(localized: "profile.verificationFailed"),
                    message: authViewModel.errorMessage ?? String(localized: "profile.pleaseTryAgain")
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
                title: String(format: NSLocalizedString("profile.urlUnavailable", comment:""), name),
                message: String(localized: "profile.linkNotConfigured")
            )
            return
        }

        openURL(url) { accepted in
            if !accepted {
                Task { @MainActor in
                    presentFeedback(
                        title: String(format: NSLocalizedString("profile.urlUnavailable", comment:""), name),
                        message: String(localized: "profile.unableToOpenLink")
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
        AppLanguage.allCases.map { ($0.nativeDisplayName, $0.rawValue) }
    }

    private var learningContentLabel: String {
        preferences.effectiveLearningLanguage.nativeDisplayName
    }

    private var reauthSheet: some View {
        NavigationStack {
            ZStack {
                ProfileSettingsPalette.background.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 14) {
                    Text(L10n.Profile.forSecurityConfirmYourPasswordToContinueAccountDeletion)
                        .font(.system(size: 13))
                        .foregroundStyle(ProfileSettingsPalette.muted)

                    SecureField(String(localized: "profile.currentPassword"), text: $reauthPassword)
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
                            Text(isReauthenticating ? String(localized: "profile.verifying") : String(localized: "profile.verifyAndDelete"))
                        }
                    }
                    .buttonStyle(AppFilledButtonStyle(tone: .danger))
                    .disabled(isReauthenticating || reauthPassword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(20)
            }
            .navigationTitle(L10n.Profile.confirmPassword)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L10n.Profile.cancel) {
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
