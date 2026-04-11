//
//  AddDailyTipView.swift
//  FinaLit
//

import SwiftUI

struct AddDailyTipView: View {
    @Environment(AdminViewModel.self) private var adminVM
    @Environment(Coordinator<AdminPages>.self) private var coordinator

    var body: some View {
        var adminVM = Bindable(adminVM)
        AdminFormView(title: "Add Daily Tip", icon: "lightbulb.fill") {
            AdminField(label: "DOCUMENT ID (OPTIONAL)", placeholder: "Reuse an existing tip ID to update the same document", text: adminVM.tipDocumentID)
            Button("Load Existing Tip") {
                Task { _ = await self.adminVM.loadDailyTipForEditing() }
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color(hex: "6366F1"))
            .frame(maxWidth: .infinity, alignment: .leading)
            AdminField(label: "TITLE", placeholder: "The 50/30/20 Rule", text: adminVM.tipTitle)
            AdminTextArea(label: "BODY", placeholder: "Explain the concept clearly in 2-3 sentences...", text: adminVM.tipBody)
            AdminField(label: "CATEGORY", placeholder: "Budgeting", text: adminVM.tipCategory)
            AdminTranslationSection(title: "AZERBAIJANI TRANSLATION (OPTIONAL)") {
                AdminField(label: "TITLE (AZ)", placeholder: "50/30/20 qaydası", text: adminVM.tipTitleAZ)
                AdminTextArea(label: "BODY (AZ)", placeholder: "Aydın izah...", text: adminVM.tipBodyAZ)
                AdminField(label: "CATEGORY (AZ)", placeholder: "Büdcə", text: adminVM.tipCategoryAZ)
            }
            AdminTranslationSection(title: "RUSSIAN TRANSLATION (OPTIONAL)") {
                AdminField(label: "TITLE (RU)", placeholder: "Правило 50/30/20", text: adminVM.tipTitleRU)
                AdminTextArea(label: "BODY (RU)", placeholder: "Понятное объяснение...", text: adminVM.tipBodyRU)
                AdminField(label: "CATEGORY (RU)", placeholder: "Бюджет", text: adminVM.tipCategoryRU)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("SHOW ON DATE")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color(hex: "4B5563"))
                DatePicker("", selection: adminVM.tipDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .tint(Color(hex: "6366F1"))
                    .colorScheme(.dark)
            }

            AdminSaveButton(label: "Save Tip", isLoading: self.adminVM.isLoading) {
                Task {
                    let saved = await self.adminVM.saveDailyTip()
                    if saved { coordinator.pop() }
                }
            }
        }
        .adminFeedback(success: self.adminVM.successMessage, error: self.adminVM.errorMessage) {
            self.adminVM.clearMessages()
        }
    }
}
