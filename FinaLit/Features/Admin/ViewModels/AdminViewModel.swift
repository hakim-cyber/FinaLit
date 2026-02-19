//
//  AdminViewModel.swift
//  FinaLit
//
//  Created by aplle on 2/20/26.
//


// AdminViewModel.swift
// Features/Admin/ViewModels/

import Foundation

@Observable
final class AdminViewModel {

    // MARK: - Week Form
    var weekNumber:      String = ""
    var weekTitle:       String = ""
    var weekDescription: String = ""
    var isPublished:     Bool   = false

    // MARK: - Day Form
    var dayNumber:    String = ""
    var lessonID:     String = ""
    var quizID:       String = ""
    var isReflection: Bool   = false

    // MARK: - Lesson Form
    var lessonWeekNumber:  String = ""
    var lessonDayNumber:   String = ""
    var lessonCategory:    String = ""
    var lessonTitle:       String = ""
    var conceptDefinition: String = ""
    var whyItMatters:      String = ""
    var realLifeExample:   String = ""
    var miniCaseScenario:  String = ""
    var dailyActionTask:   String = ""
    var difficultyLevel:   DifficultyLevel = .beginner

    // MARK: - Quiz Form
    var quizWeekNumber: String = ""
    var quizDayNumber:  String = ""
    var questions:      [QuizQuestionDraft] = [QuizQuestionDraft()]

    // MARK: - Daily Tip Form
    var tipTitle:    String = ""
    var tipBody:     String = ""
    var tipCategory: String = ""
    var tipDate:     Date   = Date()

    // MARK: - Existing data (for pickers)
    var existingWeeks: [Week] = []
    var existingDays:  [Day]  = []

    // MARK: - UI State
    var isLoading:      Bool    = false
    var successMessage: String? = nil
    var errorMessage:   String? = nil

    // MARK: - Dependencies
    private let db: DatabaseService

    init(db: DatabaseService) {
        self.db = db
    }

    // MARK: - Load existing data
    func loadWeeks() async {
        do {
            existingWeeks = try await db.fetchPublishedWeeks()
            // Also fetch unpublished — admin sees all
            // For now fetchPublishedWeeks works, extend later
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadDays(weekID: String) async {
        do {
            existingDays = try await db.fetchDays(weekID: weekID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Save Week
    func saveWeek() async -> Bool {
        guard !weekTitle.isEmpty, !weekNumber.isEmpty else {
            errorMessage = "Week number and title are required."
            return false
        }
        isLoading    = true
        errorMessage = nil
        defer { isLoading = false }

        let id = UUID().uuidString
        let week = Week(
            id:          id,
            weekNumber:  Int(weekNumber) ?? 0,
            title:       weekTitle,
            description: weekDescription,
            isPublished: isPublished
        )

        do {
            try db.createWeek(week)
            successMessage = "Week '\(weekTitle)' saved ✓"
            clearWeekForm()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Save Day
    func saveDay(weekID: String) async -> Bool {
        guard !dayNumber.isEmpty else {
            errorMessage = "Day number is required."
            return false
        }
        isLoading    = true
        errorMessage = nil
        defer { isLoading = false }

        let id = UUID().uuidString
        let day = Day(
            id:           id,
            dayNumber:    Int(dayNumber) ?? 0,
            lessonID:     isReflection ? "" : lessonID,
            quizID:       isReflection ? "" : quizID,
            isReflection: isReflection
        )

        do {
            try db.createDay(day, weekID: weekID)
            successMessage = "Day \(dayNumber) saved ✓"
            clearDayForm()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Save Lesson
    func saveLesson() async -> (Bool, String) {
        guard !lessonTitle.isEmpty,
              !conceptDefinition.isEmpty else {
            errorMessage = "Title and definition are required."
            return (false, "")
        }
        isLoading    = true
        errorMessage = nil
        defer { isLoading = false }

        let id = UUID().uuidString
        let lesson = Lesson(
            id:                id,
            weekNumber:        Int(lessonWeekNumber) ?? 0,
            dayNumber:         Int(lessonDayNumber) ?? 0,
            category:          lessonCategory,
            title:             lessonTitle,
            conceptDefinition: conceptDefinition,
            whyItMatters:      whyItMatters,
            realLifeExample:   realLifeExample,
            miniCaseScenario:  miniCaseScenario,
            dailyActionTask:   dailyActionTask,
            difficultyLevel:   difficultyLevel.rawValue
        )

        do {
            try db.createLesson(lesson)
            successMessage = "Lesson '\(lessonTitle)' saved ✓\nLesson ID: \(id)"
            clearLessonForm()
            return (true, id)
        } catch {
            errorMessage = error.localizedDescription
            return (false, "")
        }
    }

    // MARK: - Save Quiz
    func saveQuiz() async -> (Bool, String) {
        guard questions.allSatisfy({ $0.isValid }) else {
            errorMessage = "All questions need text, 4 options, and a correct answer."
            return (false, "")
        }
        isLoading    = true
        errorMessage = nil
        defer { isLoading = false }

        let id = UUID().uuidString
        let builtQuestions: [QuizQuestion] = questions.map { draft in
            QuizQuestion(
                id:           UUID().uuidString,
                questionText: draft.questionText,
                type:         draft.type.rawValue,
                options:      draft.options,
                correctIndex: draft.correctIndex,
                explanation:  draft.explanation
            )
        }

        let quiz = Quiz(
            id:          id,
            weekNumber:  Int(quizWeekNumber) ?? 0,
            dayNumber:   Int(quizDayNumber) ?? 0,
            questions:   builtQuestions
        )

        do {
            try db.createQuiz(quiz)
            successMessage = "Quiz saved ✓\nQuiz ID: \(id)"
            clearQuizForm()
            return (true, id)
        } catch {
            errorMessage = error.localizedDescription
            return (false, "")
        }
    }

    // MARK: - Save Daily Tip
    func saveDailyTip() async -> Bool {
        guard !tipTitle.isEmpty, !tipBody.isEmpty else {
            errorMessage = "Title and body are required."
            return false
        }
        isLoading    = true
        errorMessage = nil
        defer { isLoading = false }

        let tip = DailyTip(
            id:       UUID().uuidString,
            title:    tipTitle,
            body:     tipBody,
            date:     tipDate,
            category: tipCategory
        )

        do {
            try db.createDailyTip(tip)
            successMessage = "Daily tip saved ✓"
            clearTipForm()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Quiz question helpers
    func addQuestion() {
        questions.append(QuizQuestionDraft())
    }

    func removeQuestion(at index: Int) {
        guard questions.count > 1 else { return }
        questions.remove(at: index)
    }

    // MARK: - Clear forms
    func clearWeekForm() {
        weekNumber = ""; weekTitle = ""; weekDescription = ""; isPublished = false
    }
    func clearDayForm() {
        dayNumber = ""; lessonID = ""; quizID = ""; isReflection = false
    }
    func clearLessonForm() {
        lessonWeekNumber = ""; lessonDayNumber = ""; lessonCategory = ""
        lessonTitle = ""; conceptDefinition = ""; whyItMatters = ""
        realLifeExample = ""; miniCaseScenario = ""; dailyActionTask = ""
        difficultyLevel = .beginner
    }
    func clearQuizForm() {
        quizWeekNumber = ""; quizDayNumber = ""
        questions = [QuizQuestionDraft()]
    }
    func clearTipForm() {
        tipTitle = ""; tipBody = ""; tipCategory = ""; tipDate = Date()
    }

    func clearMessages() {
        errorMessage = nil; successMessage = nil
    }
}

// MARK: - Quiz Question Draft
// In-memory draft for building quiz questions in the form
// Converted to QuizQuestion on save
struct QuizQuestionDraft: Identifiable {
    let id    = UUID()
    var questionText: String        = ""
    var type:         QuizQuestionType = .multipleChoice
    var options:      [String]      = ["", "", "", ""]
    var correctIndex: Int           = 0
    var explanation:  String        = ""

    var isValid: Bool {
        !questionText.isEmpty &&
        options.filter { !$0.isEmpty }.count == 4 &&
        !explanation.isEmpty
    }
}
