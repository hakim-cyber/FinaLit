//
//  PersonalInfoEditView.swift
//  FinaLit
//

import SwiftUI

struct PersonalInfoEditView: View {
    @Environment(UserSession.self) private var session
    @Environment(DatabaseService.self) private var dbService

    @State private var name = ""
    @State private var age: Double = 22
    @State private var country = AppRegion.defaultCountry
    @State private var employmentStatus: EmploymentStatus = .employed
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var didLoad = false

    private var canSave: Bool {
        !settingsTrimmed(name).isEmpty &&
        !settingsTrimmed(country).isEmpty &&
        age >= 13 &&
        !isSaving
    }

    private var appLanguage: AppLanguage {
        session.currentAppLanguage
    }

    private func localized(_ key: String, _ arguments: CVarArg...) -> String {
        L10n.tr(key, language: appLanguage, arguments: arguments)
    }

    var body: some View {
        ProfileSettingsFormScaffold(
            title: "Personal Info",
            subtitle: "Keep your identity and lifestyle context up to date.",
            errorMessage: errorMessage,
            successMessage: successMessage,
            isLoading: isSaving,
            primaryTitle: "Save Changes",
            isPrimaryEnabled: canSave,
            onPrimaryTap: save
        ) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Name")
                        .settingsFieldLabelStyle()
                    TextField("Your name", text: $name)
                        .textInputAutocapitalization(.words)
                        .settingsInputStyle()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Email (display only)")
                        .settingsFieldLabelStyle()
                    Text(session.user?.email ?? "No email")
                        .font(.system(size: 15))
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 14)
                        .frame(height: 50)
                        .background(ProfileSettingsPalette.surface, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(ProfileSettingsPalette.border, lineWidth: 1)
                        )
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Age")
                            .settingsFieldLabelStyle()
                        Spacer()
                        Text("\(Int(age.rounded()))")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(ProfileSettingsPalette.accent)
                    }
                    Slider(value: $age, in: 13...80, step: 1)
                        .tint(ProfileSettingsPalette.accent)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Country")
                        .settingsFieldLabelStyle()
                    TextField("Country", text: $country)
                        .textInputAutocapitalization(.words)
                        .settingsInputStyle()
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Employment status")
                        .settingsFieldLabelStyle()

                    ForEach(EmploymentStatus.allCases) { status in
                        ProfileSettingsSelectableRow(
                            title: status.rawValue,
                            subtitle: status.description,
                            isSelected: employmentStatus == status,
                            accent: ProfileSettingsPalette.accent
                        ) {
                            employmentStatus = status
                            clearMessages()
                        }
                    }
                }
            }
            .onChange(of: name) { _, _ in clearMessages() }
            .onChange(of: country) { _, _ in clearMessages() }
            .onChange(of: age) { _, _ in clearMessages() }
        }
        .task {
            guard !didLoad else { return }
            didLoad = true

            let profile = session.user?.profile ?? fallbackUserProfile(from: session.user)
            name = profile.name
            age = Double(profile.age)
            country = profile.country
            employmentStatus = profile.employmentStatus
        }
    }

    private func save() {
        guard let uid = session.user?.id else {
            errorMessage = localized("Session expired. Please log in again.")
            return
        }

        let trimmedName = settingsTrimmed(name)
        let trimmedCountry = settingsTrimmed(country)
        guard !trimmedName.isEmpty, !trimmedCountry.isEmpty else {
            errorMessage = localized("Name and country are required.")
            return
        }

        isSaving = true
        clearMessages()

        Task { @MainActor in
            let currentProfile = session.user?.profile ?? fallbackUserProfile(from: session.user)
            let updatedProfile = UserProfile(
                name: trimmedName,
                age: Int(age.rounded()),
                country: trimmedCountry,
                employmentStatus: employmentStatus,
                monthlyIncome: currentProfile.monthlyIncome,
                incomeStability: currentProfile.incomeStability
            )

            do {
                try dbService.saveUserProfile(updatedProfile, uid: uid)
                try await dbService.updateUser(uid: uid, data: ["name": trimmedName])
                session.updateProfile(updatedProfile)
                session.updateName(trimmedName)
                successMessage = localized("Personal info updated.")
            } catch {
                errorMessage = error.localizedDescription
            }

            isSaving = false
        }
    }

    private func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}
