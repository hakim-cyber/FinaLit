//
//  AddWeekView.swift
//  FinaLit
//

import SwiftUI

struct AddWeekView: View {
    @Environment(AdminViewModel.self) private var adminVM
    @Environment(Coordinator<AdminPages>.self) private var coordinator

    var body: some View {
        var adminVM = Bindable(adminVM)
        AdminFormView(title: "Add Week", icon: "calendar.badge.plus") {
            AdminField(label: "DOCUMENT ID (OPTIONAL)", placeholder: "Reuse an existing week ID to update the same document", text: adminVM.weekDocumentID)
            Button("Load Existing Week") {
                Task { _ = await self.adminVM.loadWeekForEditing() }
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color(hex: "6366F1"))
            .frame(maxWidth: .infinity, alignment: .leading)
            AdminField(label: "WEEK NUMBER", placeholder: "1", text: adminVM.weekNumber)
                .keyboardType(.numberPad)

            AdminField(label: "TITLE", placeholder: "Week 1 – Foundations of Financial Thinking", text: adminVM.weekTitle)
            AdminField(label: "DESCRIPTION", placeholder: "Core concepts to start your journey", text: adminVM.weekDescription)
            AdminTranslationSection(title: "AZERBAIJANI TRANSLATION (OPTIONAL)") {
                AdminField(label: "TITLE (AZ)", placeholder: "1-ci həftə - əsaslar", text: adminVM.weekTitleAZ)
                AdminField(label: "DESCRIPTION (AZ)", placeholder: "Səyahətə başlamaq üçün əsas anlayışlar", text: adminVM.weekDescriptionAZ)
            }
            AdminTranslationSection(title: "RUSSIAN TRANSLATION (OPTIONAL)") {
                AdminField(label: "TITLE (RU)", placeholder: "Неделя 1 - основы", text: adminVM.weekTitleRU)
                AdminField(label: "DESCRIPTION (RU)", placeholder: "Базовые концепции для старта", text: adminVM.weekDescriptionRU)
            }
            AdminToggle(label: "PUBLISH NOW", isOn: adminVM.isPublished)

            if !adminVM.isPublished.wrappedValue {
                Text("Draft weeks are not visible to users until published.")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "4B5563"))
            }

            AdminSaveButton(label: "Save Week", isLoading: adminVM.isLoading.wrappedValue) {
                Task {
                    let saved = await self.adminVM.saveWeek()
                    if saved { coordinator.pop() }
                }
            }
        }
        .adminFeedback(success: adminVM.successMessage.wrappedValue, error: adminVM.errorMessage.wrappedValue) {
            self.adminVM.clearMessages()
        }
    }
}
