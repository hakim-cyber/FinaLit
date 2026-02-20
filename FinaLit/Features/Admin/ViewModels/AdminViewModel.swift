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

    // MARK: - Bulk Import Form
    var bulkImportJSON: String = ""
    var bulkImportGeneratedIDs: String = ""

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
            existingWeeks = try await db.fetchAllWeeks()
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

    // MARK: - Bulk Import
    var bulkImportTemplate: String { Self.bulkImportTemplateJSON }

    func importFromBulkJSON() async -> Bool {
        guard !bulkImportJSON.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Paste a JSON payload first."
            return false
        }

        isLoading    = true
        errorMessage = nil
        successMessage = nil
        bulkImportGeneratedIDs = ""
        defer { isLoading = false }

        do {
            let payload = try decodeBulkImportPayload(from: bulkImportJSON)
            let summary = try runBulkImport(payload)
            successMessage = summary
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func runBulkImport(_ payload: BulkImportPayload) throws -> String {
        let weeks = payload.weeks ?? []
        let lessons = payload.lessons ?? []
        let quizzes = payload.quizzes ?? []
        let days = payload.days ?? []
        let dailyTips = payload.dailyTips ?? []

        guard !(weeks.isEmpty && lessons.isEmpty && quizzes.isEmpty && days.isEmpty && dailyTips.isEmpty) else {
            throw AdminBulkImportError.emptyPayload
        }

        var weekAliasToID: [String: String] = [:]
        var weekNumberToID: [Int: String] = [:]
        var lessonAliasToID: [String: String] = [:]
        var quizAliasToID: [String: String] = [:]
        var generatedLines: [String] = []

        var createdWeeks = 0
        var createdLessons = 0
        var createdQuizzes = 0
        var createdDays = 0
        var createdTips = 0

        for week in weeks {
            let weekID = resolvedID(week.id)
            let model = Week(
                id: weekID,
                weekNumber: week.weekNumber,
                title: week.title,
                description: week.description,
                isPublished: week.isPublished ?? false
            )
            try db.createWeek(model)
            createdWeeks += 1
            weekNumberToID[week.weekNumber] = weekID
            generatedLines.append("week[\(week.weekNumber)] = \(weekID)")

            if let alias = normalizedValue(week.alias) {
                if weekAliasToID[alias] != nil {
                    throw AdminBulkImportError.duplicateAlias(type: "week", alias: alias)
                }
                weekAliasToID[alias] = weekID
                generatedLines.append("week.\(alias) = \(weekID)")
            }
        }

        for lesson in lessons {
            let lessonID = resolvedID(lesson.id)
            let difficulty = resolvedDifficulty(lesson.difficultyLevel)
            let model = Lesson(
                id: lessonID,
                weekNumber: lesson.weekNumber,
                dayNumber: lesson.dayNumber,
                category: lesson.category,
                title: lesson.title,
                conceptDefinition: lesson.conceptDefinition,
                whyItMatters: lesson.whyItMatters,
                realLifeExample: lesson.realLifeExample,
                miniCaseScenario: lesson.miniCaseScenario,
                dailyActionTask: lesson.dailyActionTask,
                difficultyLevel: difficulty.rawValue
            )
            try db.createLesson(model)
            createdLessons += 1
            generatedLines.append("lesson[w\(lesson.weekNumber)-d\(lesson.dayNumber)] = \(lessonID)")

            if let alias = normalizedValue(lesson.alias) {
                if lessonAliasToID[alias] != nil {
                    throw AdminBulkImportError.duplicateAlias(type: "lesson", alias: alias)
                }
                lessonAliasToID[alias] = lessonID
                generatedLines.append("lesson.\(alias) = \(lessonID)")
            }
        }

        for quiz in quizzes {
            let quizID = resolvedID(quiz.id)
            let questions = quiz.questions.map { question in
                QuizQuestion(
                    id: resolvedID(question.id),
                    questionText: question.questionText,
                    type: resolvedQuestionType(question.type).rawValue,
                    options: question.options,
                    correctIndex: question.correctIndex,
                    explanation: question.explanation
                )
            }

            let model = Quiz(
                id: quizID,
                weekNumber: quiz.weekNumber,
                dayNumber: quiz.dayNumber,
                questions: questions
            )
            try db.createQuiz(model)
            createdQuizzes += 1
            generatedLines.append("quiz[w\(quiz.weekNumber)-d\(quiz.dayNumber)] = \(quizID)")

            if let alias = normalizedValue(quiz.alias) {
                if quizAliasToID[alias] != nil {
                    throw AdminBulkImportError.duplicateAlias(type: "quiz", alias: alias)
                }
                quizAliasToID[alias] = quizID
                generatedLines.append("quiz.\(alias) = \(quizID)")
            }
        }

        for day in days {
            let weekID = try resolveWeekID(
                day: day,
                weekAliasToID: weekAliasToID,
                weekNumberToID: weekNumberToID
            )

            let isReflection = day.isReflection ?? false
            let dayID = resolvedID(day.id)
            let lessonID: String
            let quizID: String

            if isReflection {
                lessonID = ""
                quizID = ""
            } else {
                lessonID = try resolveLinkedContentID(
                    directID: day.lessonID,
                    alias: day.lessonRef,
                    aliases: lessonAliasToID,
                    kind: "lesson"
                )
                quizID = try resolveLinkedContentID(
                    directID: day.quizID,
                    alias: day.quizRef,
                    aliases: quizAliasToID,
                    kind: "quiz"
                )
            }

            let model = Day(
                id: dayID,
                dayNumber: day.dayNumber,
                lessonID: lessonID,
                quizID: quizID,
                isReflection: isReflection
            )
            try db.createDay(model, weekID: weekID)
            createdDays += 1
            generatedLines.append("day[\(weekID):\(day.dayNumber)] = \(dayID)")
        }

        for tip in dailyTips {
            guard let parsedDate = parseImportDate(tip.date) else {
                throw AdminBulkImportError.invalidTipDate(tip.date)
            }
            let tipID = resolvedID(tip.id)
            let model = DailyTip(
                id: tipID,
                title: tip.title,
                body: tip.body,
                date: parsedDate,
                category: tip.category
            )
            try db.createDailyTip(model)
            createdTips += 1
            generatedLines.append("tip[\(tip.title)] = \(tipID)")
        }

        bulkImportGeneratedIDs = generatedLines.joined(separator: "\n")
        return """
        Bulk import complete ✓
        Weeks: \(createdWeeks), Lessons: \(createdLessons), Quizzes: \(createdQuizzes), Days: \(createdDays), Tips: \(createdTips)
        """
    }

    private func decodeBulkImportPayload(from rawText: String) throws -> BulkImportPayload {
        let cleaned = cleanedBulkJSONString(rawText)
        guard let data = cleaned.data(using: .utf8) else {
            throw AdminBulkImportError.invalidJSON("Payload could not be converted to UTF-8.")
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        do {
            return try decoder.decode(BulkImportPayload.self, from: data)
        } catch {
            throw AdminBulkImportError.invalidJSON(error.localizedDescription)
        }
    }

    private func cleanedBulkJSONString(_ input: String) -> String {
        var text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.hasPrefix("```") {
            var lines = text.components(separatedBy: "\n")
            if lines.first?.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("```") == true {
                lines.removeFirst()
            }
            if lines.last?.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("```") == true {
                lines.removeLast()
            }
            text = lines.joined(separator: "\n")
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func resolvedID(_ raw: String?) -> String {
        normalizedValue(raw) ?? UUID().uuidString
    }

    private func normalizedValue(_ raw: String?) -> String? {
        guard let raw else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func resolvedDifficulty(_ raw: String?) -> DifficultyLevel {
        guard let value = normalizedValue(raw) else { return .beginner }
        if let level = DifficultyLevel(rawValue: value) { return level }

        switch value.lowercased() {
        case "beginner":
            return .beginner
        case "intermediate":
            return .intermediate
        case "advanced":
            return .advanced
        default:
            return .beginner
        }
    }

    private func resolvedQuestionType(_ raw: String?) -> QuizQuestionType {
        guard let value = normalizedValue(raw) else { return .multipleChoice }
        if let type = QuizQuestionType(rawValue: value) { return type }

        switch value.lowercased() {
        case "scenario":
            return .scenario
        default:
            return .multipleChoice
        }
    }

    private func resolveWeekID(
        day: BulkDayImport,
        weekAliasToID: [String: String],
        weekNumberToID: [Int: String]
    ) throws -> String {
        if let weekID = normalizedValue(day.weekID) {
            return weekID
        }

        if let alias = normalizedValue(day.weekAlias) {
            guard let resolved = weekAliasToID[alias] else {
                throw AdminBulkImportError.missingReference(kind: "week alias", value: alias)
            }
            return resolved
        }

        if let number = day.weekNumber, let resolved = weekNumberToID[number] {
            return resolved
        }

        throw AdminBulkImportError.missingWeekReference(dayNumber: day.dayNumber)
    }

    private func resolveLinkedContentID(
        directID: String?,
        alias: String?,
        aliases: [String: String],
        kind: String
    ) throws -> String {
        if let directID = normalizedValue(directID) {
            return directID
        }

        if let alias = normalizedValue(alias) {
            guard let resolved = aliases[alias] else {
                throw AdminBulkImportError.missingReference(kind: "\(kind) alias", value: alias)
            }
            return resolved
        }

        throw AdminBulkImportError.missingRequiredField("Day requires \(kind)ID or \(kind)Ref when isReflection is false.")
    }

    private func parseImportDate(_ raw: String) -> Date? {
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return nil }

        if let date = Self.iso8601WithFractional.date(from: value) { return date }
        if let date = Self.iso8601NoFractional.date(from: value) { return date }

        for formatter in Self.importDateFormatters {
            if let date = formatter.date(from: value) {
                return date
            }
        }
        return nil
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

    private static let iso8601NoFractional = ISO8601DateFormatter()
    private static let iso8601WithFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let importDateFormatters: [DateFormatter] = {
        let ymd = DateFormatter()
        ymd.dateFormat = "yyyy-MM-dd"
        ymd.locale = Locale(identifier: "en_US_POSIX")

        let ymdSlashes = DateFormatter()
        ymdSlashes.dateFormat = "yyyy/MM/dd"
        ymdSlashes.locale = Locale(identifier: "en_US_POSIX")

        let mdy = DateFormatter()
        mdy.dateFormat = "MM/dd/yyyy"
        mdy.locale = Locale(identifier: "en_US_POSIX")

        return [ymd, ymdSlashes, mdy]
    }()

    private static let bulkImportTemplateJSON = """
    {
      "weeks": [
        {
          "alias": "w1",
          "weekNumber": 1,
          "title": "Week 1 - Foundations",
          "description": "Core concepts to start your journey",
          "isPublished": true
        }
      ],
      "lessons": [
        {
          "alias": "l1d1",
          "weekNumber": 1,
          "dayNumber": 1,
          "category": "Budgeting",
          "title": "Opportunity Cost",
          "conceptDefinition": "Definition...",
          "whyItMatters": "Why it matters...",
          "realLifeExample": "Example...",
          "miniCaseScenario": "Scenario...",
          "dailyActionTask": "Action...",
          "difficultyLevel": "Beginner"
        }
      ],
      "quizzes": [
        {
          "alias": "q1d1",
          "weekNumber": 1,
          "dayNumber": 1,
          "questions": [
            {
              "questionText": "Sample question?",
              "type": "multipleChoice",
              "options": ["A", "B", "C", "D"],
              "correctIndex": 0,
              "explanation": "Explanation..."
            }
          ]
        }
      ],
      "days": [
        {
          "weekAlias": "w1",
          "dayNumber": 1,
          "lessonRef": "l1d1",
          "quizRef": "q1d1",
          "isReflection": false
        },
        {
          "weekAlias": "w1",
          "dayNumber": 7,
          "isReflection": true
        }
      ],
      "dailyTips": [
        {
          "title": "Start small",
          "body": "Tip body...",
          "date": "2026-02-20",
          "category": "Mindset"
        }
      ]
    }
    """
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

private struct BulkImportPayload: Decodable {
    let weeks: [BulkWeekImport]?
    let lessons: [BulkLessonImport]?
    let quizzes: [BulkQuizImport]?
    let days: [BulkDayImport]?
    let dailyTips: [BulkDailyTipImport]?
}

private struct BulkWeekImport: Decodable {
    let alias: String?
    let id: String?
    let weekNumber: Int
    let title: String
    let description: String
    let isPublished: Bool?
}

private struct BulkLessonImport: Decodable {
    let alias: String?
    let id: String?
    let weekNumber: Int
    let dayNumber: Int
    let category: String
    let title: String
    let conceptDefinition: String
    let whyItMatters: String
    let realLifeExample: String
    let miniCaseScenario: String
    let dailyActionTask: String
    let difficultyLevel: String?
}

private struct BulkQuizImport: Decodable {
    let alias: String?
    let id: String?
    let weekNumber: Int
    let dayNumber: Int
    let questions: [BulkQuizQuestionImport]
}

private struct BulkQuizQuestionImport: Decodable {
    let id: String?
    let questionText: String
    let type: String?
    let options: [String]
    let correctIndex: Int
    let explanation: String
}

private struct BulkDayImport: Decodable {
    let id: String?
    let weekID: String?
    let weekAlias: String?
    let weekNumber: Int?
    let dayNumber: Int
    let lessonID: String?
    let lessonRef: String?
    let quizID: String?
    let quizRef: String?
    let isReflection: Bool?
}

private struct BulkDailyTipImport: Decodable {
    let id: String?
    let title: String
    let body: String
    let date: String
    let category: String
}

private enum AdminBulkImportError: LocalizedError {
    case emptyPayload
    case invalidJSON(String)
    case missingRequiredField(String)
    case missingWeekReference(dayNumber: Int)
    case missingReference(kind: String, value: String)
    case duplicateAlias(type: String, alias: String)
    case invalidTipDate(String)

    var errorDescription: String? {
        switch self {
        case .emptyPayload:
            return "Payload is empty. Add at least one section (weeks, lessons, quizzes, days, dailyTips)."
        case .invalidJSON(let message):
            return "Invalid JSON payload. \(message)"
        case .missingRequiredField(let field):
            return field
        case .missingWeekReference(let dayNumber):
            return "Day \(dayNumber) is missing weekID, weekAlias, or weekNumber."
        case .missingReference(let kind, let value):
            return "Could not resolve \(kind): '\(value)'."
        case .duplicateAlias(let type, let alias):
            return "Duplicate \(type) alias '\(alias)' in payload."
        case .invalidTipDate(let raw):
            return "Invalid daily tip date '\(raw)'. Use ISO-8601 or yyyy-MM-dd."
        }
    }
}
