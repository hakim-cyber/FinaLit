//
//  AddDayView.swift
//  FinaLit
//

import SwiftUI

struct AddDayView: View {
    let weekID: String
    @Environment(AdminViewModel.self) private var adminVM
    @Environment(Coordinator<AdminPages>.self) private var coordinator
    @State private var selectedWeekID = ""

    var body: some View {
        var adminVM = Bindable(adminVM)
        AdminFormView(title: "Add Day", icon: "plus.circle") {
            VStack(alignment: .leading, spacing: 8) {
                Text("SELECT WEEK")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color(hex: "4B5563"))
                Picker("Week", selection: $selectedWeekID) {
                    Text("Choose a week").tag("")
                    ForEach(self.adminVM.existingWeeks) { week in
                        Text(week.title).tag(week.id ?? "")
                    }
                }
                .pickerStyle(.menu)
                .tint(Color(hex: "6366F1"))
            }

            AdminField(label: "DAY NUMBER", placeholder: "1", text: adminVM.dayNumber)
                .keyboardType(.numberPad)

            AdminToggle(label: "IS REFLECTION DAY", isOn: adminVM.isReflection)

            if !self.adminVM.isReflection {
                AdminField(label: "LESSON ID", placeholder: "Paste lesson ID here", text: adminVM.lessonID)
                AdminField(label: "QUIZ ID", placeholder: "Paste quiz ID here", text: adminVM.quizID)
                Text("💡 Create the lesson and quiz first, then paste their IDs here.")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "4B5563"))
            }

            AdminSaveButton(label: "Save Day", isLoading: self.adminVM.isLoading) {
                Task {
                    let selectedID = selectedWeekID.isEmpty ? weekID : selectedWeekID
                    let saved = await self.adminVM.saveDay(weekID: selectedID)
                    if saved { coordinator.pop() }
                }
            }
        }
        .adminFeedback(success: self.adminVM.successMessage, error: self.adminVM.errorMessage) {
            self.adminVM.clearMessages()
        }
        .task { await self.adminVM.loadWeeks() }
    }
}
