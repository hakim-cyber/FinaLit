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
            AdminField(label: "TITLE", placeholder: "The 50/30/20 Rule", text: adminVM.tipTitle)
            AdminTextArea(label: "BODY", placeholder: "Explain the concept clearly in 2-3 sentences...", text: adminVM.tipBody)
            AdminField(label: "CATEGORY", placeholder: "Budgeting", text: adminVM.tipCategory)

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
