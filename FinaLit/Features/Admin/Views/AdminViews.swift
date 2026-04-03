//
//  AdminHomeView.swift
//  FinaLit
//
//  Created by aplle on 2/20/26.
//


// AdminHomeView.swift
// Features/Admin/Views/

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Admin Home
struct AdminHomeView: View {
    @Environment(Coordinator<AdminPages>.self) private var coordinator

    var body: some View {
        ZStack {
            Color(hex: "0A0A0F").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    // Section: Content
                    AdminSection(title: "LEARNING CONTENT") {
                        AdminMenuRow(
                            icon:    "calendar.badge.plus",
                            title:   "Add Week",
                            subtitle: "Create a new learning week",
                            color:   "6366F1"
                        ) { coordinator.push(.addWeek) }

                        AdminMenuRow(
                            icon:    "plus.circle",
                            title:   "Add Day to Week",
                            subtitle: "Add a day inside an existing week",
                            color:   "8B5CF6"
                        ) { coordinator.push(.addDay("")) }

                        AdminMenuRow(
                            icon:    "book.fill",
                            title:   "Add Lesson",
                            subtitle: "Create lesson content for a day",
                            color:   "06B6D4"
                        ) { coordinator.push(.addLesson("")) }

                        AdminMenuRow(
                            icon:    "questionmark.circle.fill",
                            title:   "Add Quiz",
                            subtitle: "Create a quiz with questions",
                            color:   "FACC15"
                        ) { coordinator.push(.addQuiz("")) }

                        AdminMenuRow(
                            icon:    "doc.text.fill",
                            title:   "Bulk JSON Import",
                            subtitle: "Paste one JSON payload to create everything",
                            color:   "22D3EE"
                        ) { coordinator.push(.bulkImport) }
                    }

                    AdminSection(title: "DAILY TIPS") {
                        AdminMenuRow(
                            icon:    "lightbulb.fill",
                            title:   "Add Daily Tip",
                            subtitle: "Upload a daily insight for users",
                            color:   "10B981"
                        ) { coordinator.push(.addDailyTip) }
                    }

                    Spacer(minLength: 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    coordinator.push(.settings, type: .fullScreenCover)
                } label: {
                    Image(systemName: "gearshape")
                        .foregroundStyle(Color.primary)
                }
            }
        }
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

// MARK: - Admin Section
struct AdminSection<Content: View>: View {
    let title:   String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color(hex: "4B5563"))
                .padding(.horizontal, 20)
            VStack(spacing: 1) { content }
                .background(Color(hex: "111118"))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 20)
        }
    }
}

// MARK: - Admin Menu Row
struct AdminMenuRow: View {
    let icon:     String
    let title:    String
    let subtitle: String
    let color:    String
    let onTap:    () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: color).opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .foregroundStyle(Color(hex: color))
                        .font(.system(size: 15))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: "4B5563"))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "374151"))
            }
            .padding(14)
        }
    }
}

// MARK: - Add Week View
struct AddWeekView: View {
    @Environment(AdminViewModel.self)          private var adminVM
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

// MARK: - Add Day View
struct AddDayView: View {
    let weekID: String
    @Environment(AdminViewModel.self)          private var adminVM
    @Environment(Coordinator<AdminPages>.self) private var coordinator
    @State private var selectedWeekID = ""

    var body: some View {
        var adminVM = Bindable(adminVM)
        AdminFormView(title: "Add Day", icon: "plus.circle") {

            // Week picker
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
                AdminField(label: "QUIZ ID",   placeholder: "Paste quiz ID here",   text: adminVM.quizID)
                Text("💡 Create the lesson and quiz first, then paste their IDs here.")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "4B5563"))
            }

            AdminSaveButton(label: "Save Day", isLoading: self.adminVM.isLoading) {
                Task {
                    let wID = selectedWeekID.isEmpty ? weekID : selectedWeekID
                    let saved = await self.adminVM.saveDay(weekID: wID)
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

// MARK: - Add Lesson View
struct AddLessonView: View {
    let dayID: String
    @Environment(AdminViewModel.self)          private var adminVM
    @State private var savedLessonID: String?

    var body: some View {
        var adminVM = Bindable(adminVM)
        AdminFormView(title: "Add Lesson", icon: "book.fill") {

            HStack(spacing: 12) {
                AdminField(label: "WEEK #", placeholder: "1", text: adminVM.lessonWeekNumber)
                    .keyboardType(.numberPad)
                AdminField(label: "DAY #",  placeholder: "1", text: adminVM.lessonDayNumber)
                    .keyboardType(.numberPad)
            }

            AdminField(label: "CATEGORY", placeholder: "Budgeting", text: adminVM.lessonCategory)

            AdminField(label: "TITLE", placeholder: "Opportunity Cost", text: adminVM.lessonTitle)

            // Difficulty picker
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

            // Show saved ID for copying
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

struct LessonContentBlockDraftCard: View {
    let index: Int
    @Environment(AdminViewModel.self) private var adminVM

    var body: some View {
        if adminVM.lessonBlocks.indices.contains(index) {
            let kindBinding = Binding<LessonContentBlockKind>(
                get: { adminVM.lessonBlocks[index].kind },
                set: { adminVM.lessonBlocks[index].kind = $0 }
            )
            let titleBinding = Binding<String>(
                get: { adminVM.lessonBlocks[index].title },
                set: { adminVM.lessonBlocks[index].title = $0 }
            )
            let textBinding = Binding<String>(
                get: { adminVM.lessonBlocks[index].text },
                set: { adminVM.lessonBlocks[index].text = $0 }
            )
            let itemsBinding = Binding<String>(
                get: { adminVM.lessonBlocks[index].itemsText },
                set: { adminVM.lessonBlocks[index].itemsText = $0 }
            )

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("BLOCK \(String(format: "%02d", index + 1))")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color(hex: "6366F1"))
                    Spacer()
                    Button(role: .destructive) {
                        adminVM.removeLessonBlock(at: index)
                    } label: {
                        Label("Remove", systemImage: "trash")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: "F87171"))
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("KIND")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color(hex: "4B5563"))
                    Picker("Block Kind", selection: kindBinding) {
                        ForEach(LessonContentBlockKind.allCases) {
                            Text($0.label).tag($0)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.white)
                }

                AdminField(label: "TITLE (OPTIONAL)", placeholder: "Personal Budget", text: titleBinding)

                if kindBinding.wrappedValue.usesItems {
                    AdminTextArea(
                        label: "ITEMS (ONE PER LINE)",
                        placeholder: "First point\nSecond point\nThird point",
                        text: itemsBinding,
                        minHeight: 120
                    )
                } else {
                    AdminTextArea(
                        label: "TEXT",
                        placeholder: "Write the block content here...",
                        text: textBinding,
                        minHeight: 150
                    )
                }
            }
            .padding(14)
            .background(Color(hex: "111118"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "1F2937"), lineWidth: 1)
            )
        }
    }
}

// MARK: - Add Quiz View
struct AddQuizView: View {
    let dayID: String
    @Environment(AdminViewModel.self)          private var adminVM
    @Environment(Coordinator<AdminPages>.self) private var coordinator
    @State private var savedQuizID: String?

    var body: some View {
        var adminVM = Bindable(adminVM)
        AdminFormView(title: "Add Quiz", icon: "questionmark.circle.fill") {

            HStack(spacing: 12) {
                AdminField(label: "WEEK #", placeholder: "1", text: adminVM.quizWeekNumber)
                    .keyboardType(.numberPad)
                AdminField(label: "DAY #",  placeholder: "1", text: adminVM.quizDayNumber)
                    .keyboardType(.numberPad)
            }

            // Questions
            ForEach(Array(self.adminVM.questions.enumerated()), id: \.element.id) { index, _ in
                QuizQuestionDraftView(index: index)
            }

            // Add question button
            Button {
                self.adminVM.addQuestion()
            } label: {
                HStack {
                    Image(systemName: "plus.circle")
                    Text("Add Question")
                }
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "6366F1"))
                .frame(maxWidth: .infinity)
                .padding(14)
                .background(Color(hex: "6366F1").opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            AdminSaveButton(label: "Save Quiz", isLoading: self.adminVM.isLoading) {
                Task {
                    let (saved, id) = await self.adminVM.saveQuiz()
                    if saved {
                        savedQuizID = id
                    }
                }
            }

            if let success = self.adminVM.successMessage {
                Text(success)
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "10B981"))
                    .padding(14)
                    .background(Color(hex: "10B981").opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            if let savedQuizID {
                AdminCreatedIDCard(
                    title: "Quiz ID",
                    value: savedQuizID,
                    hint: "Paste this into Add Day → QUIZ ID"
                )
            }
        }
        .adminFeedback(success: nil, error: self.adminVM.errorMessage) {
            self.adminVM.clearMessages()
        }
    }
}

// MARK: - Quiz Question Draft View
struct QuizQuestionDraftView: View {
    let index: Int
    @Environment(AdminViewModel.self) private var adminVM

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("QUESTION \(index + 1)")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color(hex: "6366F1"))
                Spacer()
                if adminVM.questions.count > 1 {
                    Button {
                        adminVM.removeQuestion(at: index)
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(Color(hex: "F87171"))
                            .font(.system(size: 13))
                    }
                }
            }

            AdminTextArea(
                label: "QUESTION TEXT",
                placeholder: "What is opportunity cost?",
                text: Binding(
                    get: { adminVM.questions[safe: index]?.questionText ?? "" },
                    set: { adminVM.questions[index].questionText = $0 }
                )
            )

            // Type picker
            Picker("Type", selection: Binding(
                get: { adminVM.questions[safe: index]?.type ?? .multipleChoice },
                set: { adminVM.questions[index].type = $0 }
            )) {
                Text("Multiple Choice").tag(QuizQuestionType.multipleChoice)
                Text("Scenario").tag(QuizQuestionType.scenario)
            }
            .pickerStyle(.segmented)
            .tint(Color(hex: "6366F1"))

            // Options
            VStack(spacing: 8) {
                ForEach(0..<4, id: \.self) { optIndex in
                    HStack(spacing: 10) {
                        // Correct answer selector
                        Button {
                            adminVM.questions[index].correctIndex = optIndex
                        } label: {
                            Image(systemName: adminVM.questions[safe: index]?.correctIndex == optIndex
                                  ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(adminVM.questions[safe: index]?.correctIndex == optIndex
                                                 ? Color(hex: "10B981") : Color(hex: "374151"))
                        }

                        TextField(
                            "Option \(["A","B","C","D"][optIndex])",
                            text: Binding(
                                get: { adminVM.questions[safe: index]?.options[safe: optIndex] ?? "" },
                                set: { adminVM.questions[index].options[optIndex] = $0 }
                            )
                        )
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                    }
                }
            }
            .padding(12)
            .background(Color(hex: "0D0D14"))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Text("● = correct answer")
                .font(.system(size: 10))
                .foregroundStyle(Color(hex: "4B5563"))

            AdminTextArea(
                label: "EXPLANATION (shown after answering)",
                placeholder: "Opportunity cost is...",
                text: Binding(
                    get: { adminVM.questions[safe: index]?.explanation ?? "" },
                    set: { adminVM.questions[index].explanation = $0 }
                )
            )
        }
        .padding(14)
        .background(Color(hex: "0D0D14"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "1F2937"), lineWidth: 1)
        )
    }
}

// MARK: - Add Daily Tip View
struct AddDailyTipView: View {
    @Environment(AdminViewModel.self)          private var adminVM
    @Environment(Coordinator<AdminPages>.self) private var coordinator

    var body: some View {
        var adminVM = Bindable(adminVM)
        AdminFormView(title: "Add Daily Tip", icon: "lightbulb.fill") {

            AdminField(label: "TITLE", placeholder: "The 50/30/20 Rule", text: adminVM.tipTitle)
            AdminTextArea(label: "BODY", placeholder: "Explain the concept clearly in 2-3 sentences...", text: adminVM.tipBody)
            AdminField(label: "CATEGORY", placeholder: "Budgeting", text: adminVM.tipCategory)

            // Date picker
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

// MARK: - Bulk Import View
struct AddBulkImportView: View {
    @Environment(AdminViewModel.self)          private var adminVM
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

// MARK: - Reusable Admin Form Components

struct AdminFormView<Content: View>: View {
    let title:   String
    let icon:    String
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            Color(hex: "0A0A0F").ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 10) {
                        Image(systemName: icon)
                            .foregroundStyle(Color(hex: "6366F1"))
                        Text(title)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(.white)
                    }
                    .padding(.top, 8)

                    content

                    Spacer(minLength: 40)
                }
                .padding(20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AdminField: View {
    let label:       String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color(hex: "4B5563"))
            TextField(placeholder, text: $text)
                .font(.system(size: 15))
                .foregroundStyle(.white)
                .padding(12)
                .background(Color(hex: "111118"))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(hex: "1F2937"), lineWidth: 1)
                )
        }
    }
}

struct AdminTextArea: View {
    let label:       String
    let placeholder: String
    @Binding var text: String
    var minHeight: CGFloat = 80

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color(hex: "4B5563"))
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "374151"))
                        .padding(12)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $text)
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "D1D5DB"))
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: minHeight)
                    .padding(8)
            }
            .background(Color(hex: "111118"))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(hex: "1F2937"), lineWidth: 1)
            )
        }
    }
}

struct AdminToggle: View {
    let label:    String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color(hex: "4B5563"))
            Spacer()
            Toggle("", isOn: $isOn)
                .tint(Color(hex: "6366F1"))
        }
    }
}

struct AdminSaveButton: View {
    let label:     String
    let isLoading: Bool
    let action:    () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .font(.system(size: 16))
                if isLoading {
                    ProgressView().tint(.white).scaleEffect(0.8)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: [Color(hex: "6366F1"), Color(hex: "4F46E5")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(isLoading)
    }
}

struct AdminCreatedIDCard: View {
    let title: String
    let value: String
    let hint: String
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color(hex: "4B5563"))

            Text(value)
                .font(.system(size: 13))
                .foregroundStyle(.white)
                .textSelection(.enabled)

            HStack(spacing: 10) {
                Button {
                    #if canImport(UIKit)
                    UIPasteboard.general.string = value
                    #endif
                    copied = true
                } label: {
                    Label(copied ? "Copied" : "Copy ID", systemImage: copied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: copied ? "10B981" : "6366F1"))
                }

                Text(hint)
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "4B5563"))
            }
        }
        .padding(14)
        .background(Color(hex: "111118"))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(hex: "1F2937"), lineWidth: 1)
        )
    }
}

// MARK: - Feedback modifier
extension View {
    func adminFeedback(success: String?, error: String?, onDismiss: @escaping () -> Void) -> some View {
        self
            .alert("Success ✓", isPresented: .constant(success != nil)) {
                Button("OK", action: onDismiss)
            } message: {
                Text(success ?? "")
            }
            .alert("Error", isPresented: .constant(error != nil)) {
                Button("OK", action: onDismiss)
            } message: {
                Text(error ?? "")
            }
    }
}

// Safe subscript for QuizQuestionDraft array
extension Array where Element == QuizQuestionDraft {
    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
}
