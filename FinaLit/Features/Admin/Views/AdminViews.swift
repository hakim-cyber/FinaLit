//
//  AdminHomeView.swift
//  FinaLit
//
//  Created by aplle on 2/20/26.
//


// AdminHomeView.swift
// Features/Admin/Views/

import SwiftUI

// MARK: - Admin Home
struct AdminHomeView: View {
    @Environment(Coordinator<AdminPages>.self) private var coordinator
    @Environment(UserSession.self)            private var session

    var body: some View {
        ZStack {
            Color(hex: "0A0A0F").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {

                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("⚙️ Admin Panel")
                            .font(.system(size: 30, weight: .light, design: .serif))
                            .foregroundStyle(.white)
                        Text("Logged in as \(session.user?.email ?? "")")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(Color(hex: "4B5563"))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

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
        .navigationBarHidden(true)
    }
}

// MARK: - Admin Section
struct AdminSection<Content: View>: View {
    let title:   String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
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
                        .font(.system(size: 15, design: .serif))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.system(size: 11, design: .monospaced))
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
                    .font(.system(size: 11, design: .monospaced))
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
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
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
                    .font(.system(size: 11, design: .monospaced))
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
    @Environment(Coordinator<AdminPages>.self) private var coordinator

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
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color(hex: "4B5563"))
                Picker("Difficulty", selection: adminVM.difficultyLevel) {
                    ForEach([DifficultyLevel.beginner, .intermediate, .advanced], id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }
                .pickerStyle(.segmented)
            }

            AdminTextArea(label: "1️⃣ WHAT IS IT (Concept Definition)", placeholder: "Short definition...", text: adminVM.conceptDefinition)
            AdminTextArea(label: "2️⃣ WHY IT MATTERS", placeholder: "Impact explanation...", text: adminVM.whyItMatters)
            AdminTextArea(label: "3️⃣ REAL-LIFE EXAMPLE", placeholder: "Relatable example...", text: adminVM.realLifeExample)
            AdminTextArea(label: "4️⃣ MINI CASE SCENARIO", placeholder: "Small decision scenario...", text: adminVM.miniCaseScenario)
            AdminTextArea(label: "5️⃣ TODAY'S ACTION", placeholder: "Practical step for today...", text: adminVM.dailyActionTask)

            AdminSaveButton(label: "Save Lesson", isLoading: self.adminVM.isLoading) {
                Task {
                    let (saved, id) = await self.adminVM.saveLesson()
                    if saved {
                        // Show ID so admin can copy it into Day
                    }
                }
            }

            // Show saved ID for copying
            if let success = self.adminVM.successMessage {
                VStack(alignment: .leading, spacing: 6) {
                    Text(success)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(Color(hex: "10B981"))
                    Text("Copy the Lesson ID above and paste it when creating the Day.")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Color(hex: "4B5563"))
                }
                .padding(14)
                .background(Color(hex: "10B981").opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .adminFeedback(success: nil, error: self.adminVM.errorMessage) {
            self.adminVM.clearMessages()
        }
    }
}

// MARK: - Add Quiz View
struct AddQuizView: View {
    let dayID: String
    @Environment(AdminViewModel.self)          private var adminVM
    @Environment(Coordinator<AdminPages>.self) private var coordinator

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
                .font(.system(size: 14, design: .monospaced))
                .foregroundStyle(Color(hex: "6366F1"))
                .frame(maxWidth: .infinity)
                .padding(14)
                .background(Color(hex: "6366F1").opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            AdminSaveButton(label: "Save Quiz", isLoading: self.adminVM.isLoading) {
                Task { let _ = await self.adminVM.saveQuiz() }
            }

            if let success = self.adminVM.successMessage {
                Text(success)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(Color(hex: "10B981"))
                    .padding(14)
                    .background(Color(hex: "10B981").opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
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
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
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
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundStyle(.white)
                    }
                }
            }
            .padding(12)
            .background(Color(hex: "0D0D14"))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Text("● = correct answer")
                .font(.system(size: 10, design: .monospaced))
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
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
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
                            .font(.system(size: 24, weight: .light, design: .serif))
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
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color(hex: "4B5563"))
            TextField(placeholder, text: $text)
                .font(.system(size: 15, design: .monospaced))
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

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color(hex: "4B5563"))
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 14, design: .serif))
                        .foregroundStyle(Color(hex: "374151"))
                        .padding(12)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $text)
                    .font(.system(size: 14, design: .serif))
                    .foregroundStyle(Color(hex: "D1D5DB"))
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 80)
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
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
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
                    .font(.system(size: 16, design: .monospaced))
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
