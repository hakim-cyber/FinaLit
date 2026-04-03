//
//  AddBulkImportView.swift
//  FinaLit
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct AddBulkImportView: View {
    @Environment(AdminViewModel.self) private var adminVM
    @State private var copiedTemplate = false
    @State private var pastedPayload = false

    var body: some View {
        var adminVM = Bindable(adminVM)
        AdminFormView(title: "Bulk JSON Import", icon: "doc.text.fill") {
            VStack(alignment: .leading, spacing: 8) {
                Text("PASTE AI JSON")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color(hex: "4B5563"))
                Text("Use one universal JSON payload to create weeks, lessons, quizzes, days, and tips in one action.")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "9CA3AF"))
            }

            AdminTextArea(
                label: "JSON PAYLOAD",
                placeholder: self.adminVM.bulkImportTemplate,
                text: adminVM.bulkImportJSON
            )
            .frame(minHeight: 320)

            HStack(spacing: 10) {
                Button {
                    #if canImport(UIKit)
                    UIPasteboard.general.string = self.adminVM.bulkImportTemplate
                    #endif
                    copiedTemplate = true
                } label: {
                    Label(copiedTemplate ? "Template Copied" : "Copy Template", systemImage: "doc.on.doc")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: copiedTemplate ? "10B981" : "6366F1"))
                }

                Button {
                    #if canImport(UIKit)
                    if let clipboard = UIPasteboard.general.string, !clipboard.isEmpty {
                        self.adminVM.bulkImportJSON = clipboard
                        pastedPayload = true
                    }
                    #endif
                } label: {
                    Label(pastedPayload ? "Pasted" : "Paste Clipboard", systemImage: "doc.text")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: pastedPayload ? "10B981" : "22D3EE"))
                }
            }

            AdminSaveButton(label: "Create All from JSON", isLoading: self.adminVM.isLoading) {
                Task { _ = await self.adminVM.importFromBulkJSON() }
            }

            if !self.adminVM.bulkImportGeneratedIDs.isEmpty {
                AdminCreatedIDCard(
                    title: "Generated IDs",
                    value: self.adminVM.bulkImportGeneratedIDs,
                    hint: "Copy and reuse these IDs in future updates"
                )
            }
        }
        .adminFeedback(success: self.adminVM.successMessage, error: self.adminVM.errorMessage) {
            self.adminVM.clearMessages()
        }
    }
}
