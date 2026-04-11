//
//  AddLessonView.swift
//  FinaLit
//

import SwiftUI

struct AddLessonView: View {
    let dayID: String
    @Environment(AdminViewModel.self) private var adminVM
    @State private var savedLessonID: String?

    var body: some View {
        var adminVM = Bindable(adminVM)
        AdminFormView(title: "Add Lesson", icon: "book.fill") {
            AdminField(label: "DOCUMENT ID (OPTIONAL)", placeholder: "Reuse an existing lesson ID to update the same document", text: adminVM.lessonDocumentID)
            Button("Load Existing Lesson") {
                Task { _ = await self.adminVM.loadLessonForEditing() }
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color(hex: "6366F1"))
            .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 12) {
                AdminField(label: "WEEK #", placeholder: "1", text: adminVM.lessonWeekNumber)
                    .keyboardType(.numberPad)
                AdminField(label: "DAY #", placeholder: "1", text: adminVM.lessonDayNumber)
                    .keyboardType(.numberPad)
            }

            AdminField(label: "CATEGORY", placeholder: "Budgeting", text: adminVM.lessonCategory)
            AdminField(label: "TITLE", placeholder: "Opportunity Cost", text: adminVM.lessonTitle)
            AdminTranslationSection(title: "AZERBAIJANI TRANSLATION (OPTIONAL)") {
                AdminField(label: "CATEGORY (AZ)", placeholder: "Büdcə", text: adminVM.lessonCategoryAZ)
                AdminField(label: "TITLE (AZ)", placeholder: "Alternativ dəyər", text: adminVM.lessonTitleAZ)
                AdminTextArea(
                    label: "BODY / ARTICLE CONTENT (AZ)",
                    placeholder: "Dərsin Azərbaycan dilində mətni...",
                    text: adminVM.lessonBodyAZ,
                    minHeight: 180
                )
            }
            AdminTranslationSection(title: "RUSSIAN TRANSLATION (OPTIONAL)") {
                AdminField(label: "CATEGORY (RU)", placeholder: "Бюджет", text: adminVM.lessonCategoryRU)
                AdminField(label: "TITLE (RU)", placeholder: "Альтернативная стоимость", text: adminVM.lessonTitleRU)
                AdminTextArea(
                    label: "BODY / ARTICLE CONTENT (RU)",
                    placeholder: "Текст урока на русском...",
                    text: adminVM.lessonBodyRU,
                    minHeight: 180
                )
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("DIFFICULTY")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color(hex: "4B5563"))
                Picker("Difficulty", selection: adminVM.difficultyLevel) {
                    ForEach([DifficultyLevel.beginner, .intermediate, .advanced], id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("CONTENT MODE")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color(hex: "4B5563"))
                Picker("Content Mode", selection: adminVM.lessonContentMode) {
                    ForEach(LessonContentMode.allCases) {
                        Text($0.label).tag($0)
                    }
                }
                .pickerStyle(.segmented)

                Text("Article keeps the lesson as long-form text. Auto and hybrid can combine text with blocks. Sectioned focuses on divided content.")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "4B5563"))
            }

            AdminTextArea(
                label: "BODY / ARTICLE CONTENT",
                placeholder: "Paste the full lesson text here. Long-form text stays readable by default, and auto mode can detect structured sections when the text is clearly divided.",
                text: adminVM.lessonBody,
                minHeight: 220
            )

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("CONTENT BLOCKS")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color(hex: "4B5563"))
                        Text("Optional blocks for sectioned or hybrid lessons. Use these when you want guaranteed divided UI.")
                            .font(.system(size: 11))
                            .foregroundStyle(Color(hex: "4B5563"))
                    }
                    Spacer()
                    Button {
                        self.adminVM.addLessonBlock()
                    } label: {
                        Label("Add Block", systemImage: "plus.circle")
                            .font(.system(size: 13))
                            .foregroundStyle(Color(hex: "6366F1"))
                    }
                }

                if self.adminVM.lessonBlocks.isEmpty {
                    Text("No blocks yet. Article mode only needs body text.")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "374151"))
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(hex: "111118"))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(hex: "1F2937"), lineWidth: 1)
                        )
                } else {
                    ForEach(Array(self.adminVM.lessonBlocks.enumerated()), id: \.element.id) { index, _ in
                        LessonContentBlockDraftCard(index: index)
                    }
                }
            }

            AdminSaveButton(label: "Save Lesson", isLoading: self.adminVM.isLoading) {
                Task {
                    let (saved, id) = await self.adminVM.saveLesson()
                    if saved {
                        savedLessonID = id
                    }
                }
            }

            if let success = self.adminVM.successMessage {
                VStack(alignment: .leading, spacing: 6) {
                    Text(success)
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: "10B981"))
                    Text("Copy the Lesson ID above and paste it when creating the Day.")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: "4B5563"))
                }
                .padding(14)
                .background(Color(hex: "10B981").opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            if let savedLessonID {
                AdminCreatedIDCard(
                    title: "Lesson ID",
                    value: savedLessonID,
                    hint: "Paste this into Add Day → LESSON ID"
                )
            }
        }
        .adminFeedback(success: nil, error: self.adminVM.errorMessage) {
            self.adminVM.clearMessages()
        }
    }
}
