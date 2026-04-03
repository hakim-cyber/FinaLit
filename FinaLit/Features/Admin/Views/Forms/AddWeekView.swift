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
            AdminField(label: "WEEK NUMBER", placeholder: "1", text: adminVM.weekNumber)
                .keyboardType(.numberPad)

            AdminField(label: "TITLE", placeholder: "Week 1 – Foundations of Financial Thinking", text: adminVM.weekTitle)
            AdminField(label: "DESCRIPTION", placeholder: "Core concepts to start your journey", text: adminVM.weekDescription)
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
