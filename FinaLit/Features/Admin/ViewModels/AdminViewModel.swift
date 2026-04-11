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
    var weekDocumentID:  String = ""
    var weekNumber:      String = ""
    var weekTitle:       String = ""
    var weekDescription: String = ""
    var weekTitleAZ:     String = ""
    var weekDescriptionAZ: String = ""
    var weekTitleRU:     String = ""
    var weekDescriptionRU: String = ""
    var isPublished:     Bool   = false

    // MARK: - Day Form
    var dayNumber:    String = ""
    var lessonID:     String = ""
    var quizID:       String = ""
    var isReflection: Bool   = false

    // MARK: - Lesson Form
    var lessonDocumentID:  String = ""
    var lessonWeekNumber:  String = ""
    var lessonDayNumber:   String = ""
    var lessonCategory:    String = ""
    var lessonTitle:       String = ""
    var lessonCategoryAZ:  String = ""
    var lessonTitleAZ:     String = ""
    var lessonBodyAZ:      String = ""
    var lessonCategoryRU:  String = ""
    var lessonTitleRU:     String = ""
    var lessonBodyRU:      String = ""
    var difficultyLevel:   DifficultyLevel = .beginner
    var lessonContentMode: LessonContentMode = .article
    var lessonBody: String = ""
    var lessonBlocks: [LessonContentBlockDraft] = []

    // MARK: - Quiz Form
    var quizDocumentID: String = ""
    var quizWeekNumber: String = ""
    var quizDayNumber:  String = ""
    var questions:      [QuizQuestionDraft] = [QuizQuestionDraft()]

    // MARK: - Daily Tip Form
    var tipDocumentID: String = ""
    var tipTitle:    String = ""
    var tipBody:     String = ""
    var tipCategory: String = ""
    var tipTitleAZ:  String = ""
    var tipBodyAZ:   String = ""
    var tipCategoryAZ: String = ""
    var tipTitleRU:  String = ""
    var tipBodyRU:   String = ""
    var tipCategoryRU: String = ""
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
    private let session: UserSession

    init(db: DatabaseService, session: UserSession) {
        self.db = db
        self.session = session
    }

    private var appLanguage: AppLanguage {
        session.currentAppLanguage
    }

    private func localized(_ key: String, _ arguments: CVarArg...) -> String {
        L10n.tr(key, language: appLanguage, arguments: arguments)
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

    func loadWeekForEditing() async -> Bool {
        let trimmedWeekID = weekDocumentID.adminCleanedText
        guard !trimmedWeekID.isEmpty else {
            errorMessage = localized("Enter a document ID first.")
            return false
        }

        isLoading = true
        errorMessage = nil
        successMessage = nil
        defer { isLoading = false }

        do {
            let week = try await db.fetchWeek(weekID: trimmedWeekID)
            populateWeekForm(with: week)
            successMessage = localized("Loaded week '%@'.", week.title)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func loadLessonForEditing() async -> Bool {
        let trimmedLessonID = lessonDocumentID.adminCleanedText
        guard !trimmedLessonID.isEmpty else {
            errorMessage = localized("Enter a document ID first.")
            return false
        }

        isLoading = true
        errorMessage = nil
        successMessage = nil
        defer { isLoading = false }

        do {
            let lesson = try await db.fetchLesson(lessonID: trimmedLessonID)
            populateLessonForm(with: lesson)
            successMessage = localized("Loaded lesson '%@'.", lesson.title)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func loadQuizForEditing() async -> Bool {
        let trimmedQuizID = quizDocumentID.adminCleanedText
        guard !trimmedQuizID.isEmpty else {
            errorMessage = localized("Enter a document ID first.")
            return false
        }

        isLoading = true
        errorMessage = nil
        successMessage = nil
        defer { isLoading = false }

        do {
            let quiz = try await db.fetchQuiz(quizID: trimmedQuizID)
            populateQuizForm(with: quiz)
            successMessage = localized("Loaded quiz '%@'.", trimmedQuizID)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func loadDailyTipForEditing() async -> Bool {
        let trimmedTipID = tipDocumentID.adminCleanedText
        guard !trimmedTipID.isEmpty else {
            errorMessage = localized("Enter a document ID first.")
            return false
        }

        isLoading = true
        errorMessage = nil
        successMessage = nil
        defer { isLoading = false }

        do {
            let tip = try await db.fetchDailyTip(tipID: trimmedTipID)
            populateDailyTipForm(with: tip)
            successMessage = localized("Loaded daily tip '%@'.", tip.title)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Save Week
    func saveWeek() async -> Bool {
        let trimmedWeekID = weekDocumentID.adminCleanedText
        let trimmedWeekTitle = weekTitle.adminCleanedText
        let trimmedWeekDescription = weekDescription.adminCleanedText

        guard !trimmedWeekTitle.isEmpty, !weekNumber.isEmpty else {
            errorMessage = localized("Week number and title are required.")
            return false
        }
        isLoading    = true
        errorMessage = nil
        defer { isLoading = false }

        let id = trimmedWeekID.isEmpty ? UUID().uuidString : trimmedWeekID
        let week = Week(
            id:          id,
            weekNumber:  Int(weekNumber) ?? 0,
            title:       trimmedWeekTitle,
            description: trimmedWeekDescription,
            isPublished: isPublished,
            translations: buildWeekTranslations()
        )

        do {
            try db.createWeek(week)
            successMessage = localized("Week '%@' saved ✓", trimmedWeekTitle)
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
            errorMessage = localized("Day number is required.")
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
            successMessage = localized("Day %@ saved ✓", dayNumber)
            clearDayForm()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Save Lesson
    func saveLesson() async -> (Bool, String) {
        let trimmedTitle = lessonTitle.adminCleanedText
        let trimmedCategory = lessonCategory.adminCleanedText
        let trimmedBody = lessonBody.adminCleanedText
        let builtBlocks = lessonBlocks.compactMap(\.builtBlock)

        guard !trimmedTitle.isEmpty else {
            errorMessage = localized("Title is required.")
            return (false, "")
        }

        guard !trimmedBody.isEmpty || !builtBlocks.isEmpty else {
            errorMessage = localized("Add lesson body text or at least one content block.")
            return (false, "")
        }
        isLoading    = true
        errorMessage = nil
        defer { isLoading = false }

        let trimmedLessonID = lessonDocumentID.adminCleanedText
        let id = trimmedLessonID.isEmpty ? UUID().uuidString : trimmedLessonID
        let lesson = Lesson(
            id: id,
            weekNumber: Int(lessonWeekNumber) ?? 0,
            dayNumber: Int(lessonDayNumber) ?? 0,
            category: trimmedCategory,
            title: trimmedTitle,
            difficultyLevel: difficultyLevel.rawValue,
            contentMode: lessonContentMode,
            body: trimmedBody,
            blocks: builtBlocks,
            translations: buildLessonTranslations(baseBlocks: builtBlocks)
        )

        do {
            try db.createLesson(lesson)
            successMessage = localized("Lesson '%@' saved ✓\nLesson ID: %@", trimmedTitle, id)
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
            errorMessage = localized("All questions need text, 4 options, and a correct answer.")
            return (false, "")
        }
        isLoading    = true
        errorMessage = nil
        defer { isLoading = false }

        let trimmedQuizID = quizDocumentID.adminCleanedText
        let id = trimmedQuizID.isEmpty ? UUID().uuidString : trimmedQuizID
        let builtQuestions: [QuizQuestion] = questions.map { draft in
            QuizQuestion(
                id:           UUID().uuidString,
                questionText: draft.questionText.adminCleanedText,
                type:         draft.type.rawValue,
                options:      draft.options.map(\.adminCleanedText),
                correctIndex: draft.correctIndex,
                explanation:  draft.explanation.adminCleanedText
            )
        }

        let quiz = Quiz(
            id:          id,
            weekNumber:  Int(quizWeekNumber) ?? 0,
            dayNumber:   Int(quizDayNumber) ?? 0,
            questions:   builtQuestions,
            translations: buildQuizTranslations(baseQuestions: builtQuestions)
        )

        do {
            try db.createQuiz(quiz)
            successMessage = localized("Quiz saved ✓\nQuiz ID: %@", id)
            clearQuizForm()
            return (true, id)
        } catch {
            errorMessage = error.localizedDescription
            return (false, "")
        }
    }

    // MARK: - Save Daily Tip
    func saveDailyTip() async -> Bool {
        let trimmedTipTitle = tipTitle.adminCleanedText
        let trimmedTipBody = tipBody.adminCleanedText
        let trimmedTipCategory = tipCategory.adminCleanedText

        guard !trimmedTipTitle.isEmpty, !trimmedTipBody.isEmpty else {
            errorMessage = localized("Title and body are required.")
            return false
        }
        isLoading    = true
        errorMessage = nil
        defer { isLoading = false }

        let trimmedTipID = tipDocumentID.adminCleanedText
        let tip = DailyTip(
            id:       trimmedTipID.isEmpty ? UUID().uuidString : trimmedTipID,
            title:    trimmedTipTitle,
            body:     trimmedTipBody,
            date:     tipDate,
            category: trimmedTipCategory,
            translations: buildDailyTipTranslations()
        )

        do {
            try db.createDailyTip(tip)
            successMessage = localized("Daily tip saved ✓")
            clearTipForm()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func buildWeekTranslations() -> LocalizedContent<WeekTranslationPayload>? {
        let az = buildWeekTranslation(title: weekTitleAZ, description: weekDescriptionAZ)
        let ru = buildWeekTranslation(title: weekTitleRU, description: weekDescriptionRU)

        guard az != nil || ru != nil else { return nil }
        return LocalizedContent(az: az, ru: ru)
    }

    private func buildWeekTranslation(title: String, description: String) -> WeekTranslationPayload? {
        let cleanedTitle = title.adminCleanedText
        let cleanedDescription = description.adminCleanedText

        guard !cleanedTitle.isEmpty || !cleanedDescription.isEmpty else { return nil }
        return WeekTranslationPayload(title: cleanedTitle, description: cleanedDescription)
    }

    private func buildLessonTranslations(
        baseBlocks: [LessonContentBlock]
    ) -> LocalizedContent<LessonTranslationPayload>? {
        let az = buildLessonTranslation(
            language: .az,
            category: lessonCategoryAZ,
            title: lessonTitleAZ,
            body: lessonBodyAZ,
            expectedBlockCount: baseBlocks.count
        )
        let ru = buildLessonTranslation(
            language: .ru,
            category: lessonCategoryRU,
            title: lessonTitleRU,
            body: lessonBodyRU,
            expectedBlockCount: baseBlocks.count
        )

        guard az != nil || ru != nil else { return nil }
        return LocalizedContent(az: az, ru: ru)
    }

    private func buildLessonTranslation(
        language: AppLanguage,
        category: String,
        title: String,
        body: String,
        expectedBlockCount: Int
    ) -> LessonTranslationPayload? {
        let cleanedCategory = category.adminCleanedText
        let cleanedTitle = title.adminCleanedText
        let cleanedBody = body.adminCleanedText
        let localizedBlocks = lessonBlocks.compactMap { $0.builtBlock(for: language) }
        let resolvedBlocks = localizedBlocks.count == expectedBlockCount ? localizedBlocks : []

        guard !cleanedCategory.isEmpty || !cleanedTitle.isEmpty || !cleanedBody.isEmpty || !resolvedBlocks.isEmpty else {
            return nil
        }

        return LessonTranslationPayload(
            category: cleanedCategory,
            title: cleanedTitle,
            body: cleanedBody,
            blocks: resolvedBlocks
        )
    }

    private func buildQuizTranslations(
        baseQuestions: [QuizQuestion]
    ) -> LocalizedContent<QuizTranslationPayload>? {
        let az = buildQuizTranslation(language: .az, baseQuestions: baseQuestions)
        let ru = buildQuizTranslation(language: .ru, baseQuestions: baseQuestions)

        guard az != nil || ru != nil else { return nil }
        return LocalizedContent(az: az, ru: ru)
    }

    private func buildQuizTranslation(
        language: AppLanguage,
        baseQuestions: [QuizQuestion]
    ) -> QuizTranslationPayload? {
        let hasAnyLocalizedContent = zip(questions, baseQuestions).contains { draft, question in
            draft.hasTranslation(for: language, baseQuestion: question)
        }

        guard hasAnyLocalizedContent else { return nil }

        let translatedQuestions = zip(questions, baseQuestions).map { draft, question in
            draft.translationPayload(for: language, baseQuestion: question)
        }

        return QuizTranslationPayload(questions: translatedQuestions)
    }

    private func buildDailyTipTranslations() -> LocalizedContent<DailyTipTranslationPayload>? {
        let az = buildDailyTipTranslation(title: tipTitleAZ, body: tipBodyAZ, category: tipCategoryAZ)
        let ru = buildDailyTipTranslation(title: tipTitleRU, body: tipBodyRU, category: tipCategoryRU)

        guard az != nil || ru != nil else { return nil }
        return LocalizedContent(az: az, ru: ru)
    }

    private func buildDailyTipTranslation(
        title: String,
        body: String,
        category: String
    ) -> DailyTipTranslationPayload? {
        let cleanedTitle = title.adminCleanedText
        let cleanedBody = body.adminCleanedText
        let cleanedCategory = category.adminCleanedText

        guard !cleanedTitle.isEmpty || !cleanedBody.isEmpty || !cleanedCategory.isEmpty else { return nil }
        return DailyTipTranslationPayload(
            title: cleanedTitle,
            body: cleanedBody,
            category: cleanedCategory
        )
    }

    private func populateWeekForm(with week: Week) {
        weekDocumentID = week.id ?? ""
        weekNumber = String(week.weekNumber)
        weekTitle = week.title
        weekDescription = week.description
        weekTitleAZ = week.translations?.az?.title ?? ""
        weekDescriptionAZ = week.translations?.az?.description ?? ""
        weekTitleRU = week.translations?.ru?.title ?? ""
        weekDescriptionRU = week.translations?.ru?.description ?? ""
        isPublished = week.isPublished
    }

    private func populateLessonForm(with lesson: Lesson) {
        lessonDocumentID = lesson.id ?? ""
        lessonWeekNumber = String(lesson.weekNumber)
        lessonDayNumber = String(lesson.dayNumber)
        lessonCategory = lesson.category
        lessonTitle = lesson.title
        lessonBody = lesson.body
        lessonCategoryAZ = lesson.translations?.az?.category ?? ""
        lessonTitleAZ = lesson.translations?.az?.title ?? ""
        lessonBodyAZ = lesson.translations?.az?.body ?? ""
        lessonCategoryRU = lesson.translations?.ru?.category ?? ""
        lessonTitleRU = lesson.translations?.ru?.title ?? ""
        lessonBodyRU = lesson.translations?.ru?.body ?? ""
        difficultyLevel = resolvedDifficulty(lesson.difficultyLevel)
        lessonContentMode = lesson.contentMode

        let baseBlocks = lesson.normalizedBlocks
        let azBlocks = lesson.translations?.az?.blocks ?? []
        let ruBlocks = lesson.translations?.ru?.blocks ?? []
        let hasAZBlocks = azBlocks.count == baseBlocks.count
        let hasRUBlocks = ruBlocks.count == baseBlocks.count

        lessonBlocks = baseBlocks.enumerated().map { index, block in
            let azBlock = hasAZBlocks ? azBlocks[index] : LessonContentBlock()
            let ruBlock = hasRUBlocks ? ruBlocks[index] : LessonContentBlock()

            return LessonContentBlockDraft(
                kind: block.kind,
                title: block.title,
                text: block.text,
                itemsText: block.items.joined(separator: "\n"),
                titleAZ: azBlock.title,
                textAZ: azBlock.text,
                itemsTextAZ: azBlock.items.joined(separator: "\n"),
                titleRU: ruBlock.title,
                textRU: ruBlock.text,
                itemsTextRU: ruBlock.items.joined(separator: "\n")
            )
        }
    }

    private func populateQuizForm(with quiz: Quiz) {
        let normalizedQuiz = quiz.normalizedQuestionIDs()
        quizDocumentID = normalizedQuiz.id ?? ""
        quizWeekNumber = String(normalizedQuiz.weekNumber)
        quizDayNumber = String(normalizedQuiz.dayNumber)

        let azQuestions = normalizedQuiz.translations?.az?.questions ?? []
        let ruQuestions = normalizedQuiz.translations?.ru?.questions ?? []
        let hasAZQuestions = azQuestions.count == normalizedQuiz.questions.count
        let hasRUQuestions = ruQuestions.count == normalizedQuiz.questions.count

        questions = normalizedQuiz.questions.enumerated().map { index, question in
            let azQuestion = hasAZQuestions ? azQuestions[index] : QuizQuestionTranslationPayload()
            let ruQuestion = hasRUQuestions ? ruQuestions[index] : QuizQuestionTranslationPayload()

            return QuizQuestionDraft(
                questionText: question.questionText,
                type: resolvedQuestionType(question.type),
                options: paddedOptions(question.options),
                correctIndex: question.correctIndex,
                explanation: question.explanation,
                questionTextAZ: azQuestion.questionText,
                optionsAZ: paddedOptions(azQuestion.options),
                explanationAZ: azQuestion.explanation,
                questionTextRU: ruQuestion.questionText,
                optionsRU: paddedOptions(ruQuestion.options),
                explanationRU: ruQuestion.explanation
            )
        }
    }

    private func populateDailyTipForm(with tip: DailyTip) {
        tipDocumentID = tip.id ?? ""
        tipTitle = tip.title
        tipBody = tip.body
        tipCategory = tip.category
        tipTitleAZ = tip.translations?.az?.title ?? ""
        tipBodyAZ = tip.translations?.az?.body ?? ""
        tipCategoryAZ = tip.translations?.az?.category ?? ""
        tipTitleRU = tip.translations?.ru?.title ?? ""
        tipBodyRU = tip.translations?.ru?.body ?? ""
        tipCategoryRU = tip.translations?.ru?.category ?? ""
        tipDate = tip.date
    }

    private func paddedOptions(_ options: [String], count: Int = 4) -> [String] {
        Array(options.prefix(count)) + Array(repeating: "", count: max(count - options.count, 0))
    }

    // MARK: - Bulk Import
    var bulkImportTemplate: String { Self.bulkImportTemplateJSON }

    func importFromBulkJSON() async -> Bool {
        guard !bulkImportJSON.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = localized("Paste a JSON payload first.")
            return false
        }

        isLoading    = true
        errorMessage = nil
        successMessage = nil
        bulkImportGeneratedIDs = ""
        defer { isLoading = false }

        do {
            let payload = try decodeBulkImportPayload(from: bulkImportJSON)
            let summary = try await runBulkImport(payload)
            successMessage = summary
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func runBulkImport(_ payload: BulkImportPayload) async throws -> String {
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
            let model = try await resolvedWeekModel(from: week)
            let weekID = model.id ?? ""
            try db.createWeek(model)
            createdWeeks += 1
            weekNumberToID[model.weekNumber] = weekID
            generatedLines.append("week[\(model.weekNumber)] = \(weekID)")

            if let alias = normalizedValue(week.alias) {
                if weekAliasToID[alias] != nil {
                    throw AdminBulkImportError.duplicateAlias(type: "week", alias: alias)
                }
                weekAliasToID[alias] = weekID
                generatedLines.append("week.\(alias) = \(weekID)")
            }
        }

        for lesson in lessons {
            let model = try await resolvedLessonModel(from: lesson)
            let lessonID = model.id ?? ""
            try db.createLesson(model)
            createdLessons += 1
            generatedLines.append("lesson[w\(model.weekNumber)-d\(model.dayNumber)] = \(lessonID)")

            if let alias = normalizedValue(lesson.alias) {
                if lessonAliasToID[alias] != nil {
                    throw AdminBulkImportError.duplicateAlias(type: "lesson", alias: alias)
                }
                lessonAliasToID[alias] = lessonID
                generatedLines.append("lesson.\(alias) = \(lessonID)")
            }
        }

        for quiz in quizzes {
            let model = try await resolvedQuizModel(from: quiz)
            let quizID = model.id ?? ""
            try db.createQuiz(model)
            createdQuizzes += 1
            generatedLines.append("quiz[w\(model.weekNumber)-d\(model.dayNumber)] = \(quizID)")

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
            let model = try await resolvedDailyTipModel(from: tip)
            let tipID = model.id ?? ""
            try db.createDailyTip(model)
            createdTips += 1
            generatedLines.append("tip[\(model.title)] = \(tipID)")
        }

        bulkImportGeneratedIDs = generatedLines.joined(separator: "\n")
        return """
        Bulk import complete ✓
        Weeks: \(createdWeeks), Lessons: \(createdLessons), Quizzes: \(createdQuizzes), Days: \(createdDays), Tips: \(createdTips)
        """
    }

    private func resolvedWeekModel(from week: BulkWeekImport) async throws -> Week {
        let explicitID = normalizedValue(week.id)
        let existingWeek = try await fetchExistingWeekIfNeeded(id: explicitID)

        guard let weekNumber = week.weekNumber ?? existingWeek?.weekNumber else {
            throw AdminBulkImportError.missingRequiredField("Week requires weekNumber.")
        }

        let title = week.title?.adminCleanedText ?? existingWeek?.title ?? ""
        let description = week.description?.adminCleanedText ?? existingWeek?.description ?? ""

        guard !title.isEmpty else {
            throw AdminBulkImportError.missingRequiredField("Week \(weekNumber) requires a title or an existing document ID to merge into.")
        }

        let mergedTranslations = mergeWeekTranslations(
            existing: existingWeek?.translations,
            incoming: buildWeekTranslations(from: week.translations)
        )

        return Week(
            id: explicitID ?? existingWeek?.id ?? UUID().uuidString,
            weekNumber: weekNumber,
            title: title,
            description: description,
            isPublished: week.isPublished ?? existingWeek?.isPublished ?? false,
            translations: mergedTranslations
        )
    }

    private func resolvedLessonModel(from lesson: BulkLessonImport) async throws -> Lesson {
        let explicitID = normalizedValue(lesson.id)
        let existingLesson = try await fetchExistingLessonIfNeeded(id: explicitID)

        guard let weekNumber = lesson.weekNumber ?? existingLesson?.weekNumber else {
            throw AdminBulkImportError.missingRequiredField("Lesson requires weekNumber.")
        }

        guard let dayNumber = lesson.dayNumber ?? existingLesson?.dayNumber else {
            throw AdminBulkImportError.missingRequiredField("Lesson requires dayNumber.")
        }

        let blocks = if let importBlocks = lesson.blocks {
            importBlocks.map { block in
                LessonContentBlock(
                    id: resolvedID(block.id),
                    kind: block.kind ?? .paragraph,
                    title: block.title ?? "",
                    text: block.text ?? "",
                    items: block.items ?? []
                )
            }
        } else {
            existingLesson?.blocks ?? []
        }

        let category = lesson.category?.adminCleanedText ?? existingLesson?.category ?? ""
        let title = lesson.title?.adminCleanedText ?? existingLesson?.title ?? ""
        let body = lesson.body?.adminCleanedText ?? existingLesson?.body ?? ""
        let difficulty = resolvedDifficulty(lesson.difficultyLevel ?? existingLesson?.difficultyLevel)
        let contentMode = lesson.contentMode ?? existingLesson?.contentMode ?? .article

        guard !title.isEmpty else {
            throw AdminBulkImportError.missingRequiredField("Lesson w\(weekNumber)-d\(dayNumber) requires a title or an existing document ID to merge into.")
        }

        guard !body.isEmpty || !blocks.isEmpty else {
            throw AdminBulkImportError.missingRequiredField("Lesson w\(weekNumber)-d\(dayNumber) requires body text or content blocks.")
        }

        let mergedTranslations = mergeLessonTranslations(
            existing: existingLesson?.translations,
            incoming: buildLessonTranslations(from: lesson.translations, baseBlockCount: blocks.count),
            baseBlockCount: blocks.count
        )

        return Lesson(
            id: explicitID ?? existingLesson?.id ?? UUID().uuidString,
            weekNumber: weekNumber,
            dayNumber: dayNumber,
            category: category,
            title: title,
            difficultyLevel: difficulty.rawValue,
            contentMode: contentMode,
            body: body,
            blocks: blocks,
            translations: mergedTranslations
        )
    }

    private func resolvedQuizModel(from quiz: BulkQuizImport) async throws -> Quiz {
        let explicitID = normalizedValue(quiz.id)
        let existingQuiz = try await fetchExistingQuizIfNeeded(id: explicitID)

        guard let weekNumber = quiz.weekNumber ?? existingQuiz?.weekNumber else {
            throw AdminBulkImportError.missingRequiredField("Quiz requires weekNumber.")
        }

        guard let dayNumber = quiz.dayNumber ?? existingQuiz?.dayNumber else {
            throw AdminBulkImportError.missingRequiredField("Quiz requires dayNumber.")
        }

        let questions: [QuizQuestion] = if let importQuestions = quiz.questions {
            importQuestions.map { question in
                QuizQuestion(
                    id: resolvedID(question.id),
                    questionText: question.questionText.adminCleanedText,
                    type: resolvedQuestionType(question.type).rawValue,
                    options: question.options.map(\.adminCleanedText),
                    correctIndex: question.correctIndex,
                    explanation: question.explanation.adminCleanedText
                )
            }
        } else {
            existingQuiz?.questions ?? []
        }

        guard !questions.isEmpty else {
            throw AdminBulkImportError.missingRequiredField("Quiz w\(weekNumber)-d\(dayNumber) requires questions or an existing document ID to merge into.")
        }

        let mergedTranslations = mergeQuizTranslations(
            existing: existingQuiz?.translations,
            incoming: buildQuizTranslations(from: quiz.translations, baseQuestions: questions),
            baseQuestions: questions
        )

        return Quiz(
            id: explicitID ?? existingQuiz?.id ?? UUID().uuidString,
            weekNumber: weekNumber,
            dayNumber: dayNumber,
            questions: questions,
            translations: mergedTranslations
        )
    }

    private func resolvedDailyTipModel(from tip: BulkDailyTipImport) async throws -> DailyTip {
        let explicitID = normalizedValue(tip.id)
        let existingTip = try await fetchExistingDailyTipIfNeeded(id: explicitID)

        let title = tip.title?.adminCleanedText ?? existingTip?.title ?? ""
        let body = tip.body?.adminCleanedText ?? existingTip?.body ?? ""
        let category = tip.category?.adminCleanedText ?? existingTip?.category ?? ""

        guard !title.isEmpty, !body.isEmpty else {
            throw AdminBulkImportError.missingRequiredField("Daily tip requires title and body or an existing document ID to merge into.")
        }

        let date: Date
        if let rawDate = tip.date?.adminCleanedText, !rawDate.isEmpty {
            guard let parsedDate = parseImportDate(rawDate) else {
                throw AdminBulkImportError.invalidTipDate(rawDate)
            }
            date = parsedDate
        } else if let existingDate = existingTip?.date {
            date = existingDate
        } else {
            throw AdminBulkImportError.missingRequiredField("Daily tip requires a date or an existing document ID to merge into.")
        }

        let mergedTranslations = mergeDailyTipTranslations(
            existing: existingTip?.translations,
            incoming: buildDailyTipTranslations(from: tip.translations)
        )

        return DailyTip(
            id: explicitID ?? existingTip?.id ?? UUID().uuidString,
            title: title,
            body: body,
            date: date,
            category: category,
            translations: mergedTranslations
        )
    }

    private func fetchExistingWeekIfNeeded(id: String?) async throws -> Week? {
        guard let id else { return nil }
        do {
            return try await db.fetchWeek(weekID: id)
        } catch DBError.notFound {
            return nil
        }
    }

    private func fetchExistingLessonIfNeeded(id: String?) async throws -> Lesson? {
        guard let id else { return nil }
        do {
            return try await db.fetchLesson(lessonID: id)
        } catch DBError.notFound {
            return nil
        }
    }

    private func fetchExistingQuizIfNeeded(id: String?) async throws -> Quiz? {
        guard let id else { return nil }
        do {
            return try await db.fetchQuiz(quizID: id)
        } catch DBError.notFound {
            return nil
        }
    }

    private func fetchExistingDailyTipIfNeeded(id: String?) async throws -> DailyTip? {
        guard let id else { return nil }
        do {
            return try await db.fetchDailyTip(tipID: id)
        } catch DBError.notFound {
            return nil
        }
    }

    private func mergeWeekTranslations(
        existing: LocalizedContent<WeekTranslationPayload>?,
        incoming: LocalizedContent<WeekTranslationPayload>?
    ) -> LocalizedContent<WeekTranslationPayload>? {
        let az = mergeWeekTranslation(existing: existing?.az, incoming: incoming?.az)
        let ru = mergeWeekTranslation(existing: existing?.ru, incoming: incoming?.ru)
        guard az != nil || ru != nil else { return nil }
        return LocalizedContent(az: az, ru: ru)
    }

    private func mergeWeekTranslation(
        existing: WeekTranslationPayload?,
        incoming: WeekTranslationPayload?
    ) -> WeekTranslationPayload? {
        guard existing != nil || incoming != nil else { return nil }

        let title = normalizedValue(incoming?.title) ?? existing?.title ?? ""
        let description = normalizedValue(incoming?.description) ?? existing?.description ?? ""
        guard !title.isEmpty || !description.isEmpty else { return nil }

        return WeekTranslationPayload(title: title, description: description)
    }

    private func mergeLessonTranslations(
        existing: LocalizedContent<LessonTranslationPayload>?,
        incoming: LocalizedContent<LessonTranslationPayload>?,
        baseBlockCount: Int
    ) -> LocalizedContent<LessonTranslationPayload>? {
        let az = mergeLessonTranslation(existing: existing?.az, incoming: incoming?.az, baseBlockCount: baseBlockCount)
        let ru = mergeLessonTranslation(existing: existing?.ru, incoming: incoming?.ru, baseBlockCount: baseBlockCount)
        guard az != nil || ru != nil else { return nil }
        return LocalizedContent(az: az, ru: ru)
    }

    private func mergeLessonTranslation(
        existing: LessonTranslationPayload?,
        incoming: LessonTranslationPayload?,
        baseBlockCount: Int
    ) -> LessonTranslationPayload? {
        guard existing != nil || incoming != nil else { return nil }

        let category = normalizedValue(incoming?.category) ?? existing?.category ?? ""
        let title = normalizedValue(incoming?.title) ?? existing?.title ?? ""
        let body = normalizedValue(incoming?.body) ?? existing?.body ?? ""

        let incomingBlocks = incoming?.blocks.count == baseBlockCount ? incoming?.blocks ?? [] : []
        let existingBlocks = existing?.blocks.count == baseBlockCount ? existing?.blocks ?? [] : []
        let blocks = incomingBlocks.isEmpty ? existingBlocks : incomingBlocks

        guard !category.isEmpty || !title.isEmpty || !body.isEmpty || !blocks.isEmpty else { return nil }

        return LessonTranslationPayload(
            category: category,
            title: title,
            body: body,
            blocks: blocks
        )
    }

    private func mergeQuizTranslations(
        existing: LocalizedContent<QuizTranslationPayload>?,
        incoming: LocalizedContent<QuizTranslationPayload>?,
        baseQuestions: [QuizQuestion]
    ) -> LocalizedContent<QuizTranslationPayload>? {
        let az = mergeQuizTranslation(existing: existing?.az, incoming: incoming?.az, baseQuestions: baseQuestions)
        let ru = mergeQuizTranslation(existing: existing?.ru, incoming: incoming?.ru, baseQuestions: baseQuestions)
        guard az != nil || ru != nil else { return nil }
        return LocalizedContent(az: az, ru: ru)
    }

    private func mergeQuizTranslation(
        existing: QuizTranslationPayload?,
        incoming: QuizTranslationPayload?,
        baseQuestions: [QuizQuestion]
    ) -> QuizTranslationPayload? {
        guard existing != nil || incoming != nil else { return nil }

        let mergedQuestions = baseQuestions.enumerated().map { index, baseQuestion in
            let existingQuestion = existing?.questions[safe: index]
            let incomingQuestion = incoming?.questions[safe: index]
            let incomingOptions = incomingQuestion?.options ?? []
            let existingOptions = existingQuestion?.options ?? []

            let resolvedOptions: [String]
            if incomingOptions.count == baseQuestion.options.count && incomingOptions.allSatisfy({ !$0.adminCleanedText.isEmpty }) {
                resolvedOptions = incomingOptions.map(\.adminCleanedText)
            } else if existingOptions.count == baseQuestion.options.count && existingOptions.allSatisfy({ !$0.adminCleanedText.isEmpty }) {
                resolvedOptions = existingOptions.map(\.adminCleanedText)
            } else {
                resolvedOptions = Array(repeating: "", count: baseQuestion.options.count)
            }

            return QuizQuestionTranslationPayload(
                id: baseQuestion.id,
                questionText: normalizedValue(incomingQuestion?.questionText) ?? existingQuestion?.questionText ?? "",
                type: normalizedValue(incomingQuestion?.type) ?? existingQuestion?.type ?? baseQuestion.type,
                options: resolvedOptions,
                explanation: normalizedValue(incomingQuestion?.explanation) ?? existingQuestion?.explanation ?? ""
            )
        }

        guard mergedQuestions.contains(where: {
            !$0.questionText.isEmpty || !$0.explanation.isEmpty || $0.options.contains(where: { !$0.isEmpty })
        }) else {
            return nil
        }

        return QuizTranslationPayload(questions: mergedQuestions)
    }

    private func mergeDailyTipTranslations(
        existing: LocalizedContent<DailyTipTranslationPayload>?,
        incoming: LocalizedContent<DailyTipTranslationPayload>?
    ) -> LocalizedContent<DailyTipTranslationPayload>? {
        let az = mergeDailyTipTranslation(existing: existing?.az, incoming: incoming?.az)
        let ru = mergeDailyTipTranslation(existing: existing?.ru, incoming: incoming?.ru)
        guard az != nil || ru != nil else { return nil }
        return LocalizedContent(az: az, ru: ru)
    }

    private func mergeDailyTipTranslation(
        existing: DailyTipTranslationPayload?,
        incoming: DailyTipTranslationPayload?
    ) -> DailyTipTranslationPayload? {
        guard existing != nil || incoming != nil else { return nil }

        let title = normalizedValue(incoming?.title) ?? existing?.title ?? ""
        let body = normalizedValue(incoming?.body) ?? existing?.body ?? ""
        let category = normalizedValue(incoming?.category) ?? existing?.category ?? ""
        guard !title.isEmpty || !body.isEmpty || !category.isEmpty else { return nil }

        return DailyTipTranslationPayload(title: title, body: body, category: category)
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

    private func buildWeekTranslations(
        from translations: BulkWeekTranslationsImport?
    ) -> LocalizedContent<WeekTranslationPayload>? {
        guard let translations else { return nil }

        let az = translations.az.map {
            WeekTranslationPayload(
                title: $0.title?.adminCleanedText ?? "",
                description: $0.description?.adminCleanedText ?? ""
            )
        }
        let ru = translations.ru.map {
            WeekTranslationPayload(
                title: $0.title?.adminCleanedText ?? "",
                description: $0.description?.adminCleanedText ?? ""
            )
        }

        guard az != nil || ru != nil else { return nil }
        return LocalizedContent(az: az, ru: ru)
    }

    private func buildLessonTranslations(
        from translations: BulkLessonTranslationsImport?,
        baseBlockCount: Int
    ) -> LocalizedContent<LessonTranslationPayload>? {
        guard let translations else { return nil }

        let az = buildLessonTranslation(from: translations.az, expectedBlockCount: baseBlockCount)
        let ru = buildLessonTranslation(from: translations.ru, expectedBlockCount: baseBlockCount)

        guard az != nil || ru != nil else { return nil }
        return LocalizedContent(az: az, ru: ru)
    }

    private func buildLessonTranslation(
        from translation: BulkLessonTranslationImport?,
        expectedBlockCount: Int
    ) -> LessonTranslationPayload? {
        guard let translation else { return nil }

        let blocks = (translation.blocks ?? []).map { block in
            LessonContentBlock(
                id: resolvedID(block.id),
                kind: block.kind ?? .paragraph,
                title: block.title ?? "",
                text: block.text ?? "",
                items: block.items ?? []
            )
        }

        let resolvedBlocks = blocks.count == expectedBlockCount ? blocks : []
        let payload = LessonTranslationPayload(
            category: translation.category?.adminCleanedText ?? "",
            title: translation.title?.adminCleanedText ?? "",
            body: translation.body?.adminCleanedText ?? "",
            blocks: resolvedBlocks
        )

        guard !payload.category.isEmpty || !payload.title.isEmpty || !payload.body.isEmpty || !payload.blocks.isEmpty else {
            return nil
        }

        return payload
    }

    private func buildQuizTranslations(
        from translations: BulkQuizTranslationsImport?,
        baseQuestions: [QuizQuestion]
    ) -> LocalizedContent<QuizTranslationPayload>? {
        guard let translations else { return nil }

        let az = buildQuizTranslation(from: translations.az, baseQuestions: baseQuestions)
        let ru = buildQuizTranslation(from: translations.ru, baseQuestions: baseQuestions)

        guard az != nil || ru != nil else { return nil }
        return LocalizedContent(az: az, ru: ru)
    }

    private func buildQuizTranslation(
        from translation: BulkQuizTranslationImport?,
        baseQuestions: [QuizQuestion]
    ) -> QuizTranslationPayload? {
        guard let translation else { return nil }

        let localizedQuestions: [QuizQuestionTranslationPayload] = baseQuestions.enumerated().map { index, question in
            let localized = translation.questions[safe: index]
            return QuizQuestionTranslationPayload(
                id: question.id,
                questionText: localized?.questionText?.adminCleanedText ?? "",
                type: localized?.type?.adminCleanedText ?? question.type,
                options: (localized?.options ?? Array(repeating: "", count: question.options.count))
                    .map(\.adminCleanedText),
                explanation: localized?.explanation?.adminCleanedText ?? ""
            )
        }

        guard localizedQuestions.contains(where: {
            !$0.questionText.isEmpty || !$0.explanation.isEmpty || $0.options.contains(where: { !$0.isEmpty })
        }) else {
            return nil
        }

        return QuizTranslationPayload(questions: localizedQuestions)
    }

    private func buildDailyTipTranslations(
        from translations: BulkDailyTipTranslationsImport?
    ) -> LocalizedContent<DailyTipTranslationPayload>? {
        guard let translations else { return nil }

        let az = translations.az.map {
            DailyTipTranslationPayload(
                title: $0.title?.adminCleanedText ?? "",
                body: $0.body?.adminCleanedText ?? "",
                category: $0.category?.adminCleanedText ?? ""
            )
        }
        let ru = translations.ru.map {
            DailyTipTranslationPayload(
                title: $0.title?.adminCleanedText ?? "",
                body: $0.body?.adminCleanedText ?? "",
                category: $0.category?.adminCleanedText ?? ""
            )
        }

        guard az != nil || ru != nil else { return nil }
        return LocalizedContent(az: az, ru: ru)
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

    // MARK: - Lesson content block helpers
    func addLessonBlock() {
        lessonBlocks.append(LessonContentBlockDraft())
    }

    func removeLessonBlock(at index: Int) {
        guard lessonBlocks.indices.contains(index) else { return }
        lessonBlocks.remove(at: index)
    }

    // MARK: - Clear forms
    func clearWeekForm() {
        weekDocumentID = ""
        weekNumber = ""
        weekTitle = ""
        weekDescription = ""
        weekTitleAZ = ""
        weekDescriptionAZ = ""
        weekTitleRU = ""
        weekDescriptionRU = ""
        isPublished = false
    }
    func clearDayForm() {
        dayNumber = ""; lessonID = ""; quizID = ""; isReflection = false
    }
    func clearLessonForm() {
        lessonDocumentID = ""
        lessonWeekNumber = ""
        lessonDayNumber = ""
        lessonCategory = ""
        lessonTitle = ""
        lessonBody = ""
        lessonCategoryAZ = ""
        lessonTitleAZ = ""
        lessonBodyAZ = ""
        lessonCategoryRU = ""
        lessonTitleRU = ""
        lessonBodyRU = ""
        lessonBlocks = []
        difficultyLevel = .beginner
        lessonContentMode = .article
    }
    func clearQuizForm() {
        quizDocumentID = ""
        quizWeekNumber = ""
        quizDayNumber = ""
        questions = [QuizQuestionDraft()]
    }
    func clearTipForm() {
        tipDocumentID = ""
        tipTitle = ""
        tipBody = ""
        tipCategory = ""
        tipTitleAZ = ""
        tipBodyAZ = ""
        tipCategoryAZ = ""
        tipTitleRU = ""
        tipBodyRU = ""
        tipCategoryRU = ""
        tipDate = Date()
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
          "isPublished": true,
          "translations": {
            "az": {
              "title": "1-ci həftə - əsaslar",
              "description": "Səyahətə başlamaq üçün əsas anlayışlar"
            },
            "ru": {
              "title": "Неделя 1 - основы",
              "description": "Базовые концепции для старта"
            }
          }
        }
      ],
      "lessons": [
        {
          "alias": "l1d1",
          "weekNumber": 1,
          "dayNumber": 1,
          "category": "Budgeting",
          "title": "Opportunity Cost",
          "contentMode": "hybrid",
          "body": "Start with a short intro paragraph here.",
          "blocks": [
            {
              "kind": "section",
              "title": "What It Means",
              "text": "Explain the concept in simple language."
            },
            {
              "kind": "action",
              "title": "Today's Action",
              "text": "Write down one financial tradeoff you made this week."
            }
          ],
          "difficultyLevel": "Beginner",
          "translations": {
            "az": {
              "category": "Büdcə",
              "title": "Alternativ dəyər",
              "body": "Buraya qısa giriş mətni yazın.",
              "blocks": [
                {
                  "kind": "section",
                  "title": "Nə deməkdir",
                  "text": "Anlayışı sadə dillə izah edin."
                },
                {
                  "kind": "action",
                  "title": "Bugünkü addım",
                  "text": "Bu həftə etdiyiniz bir maliyyə seçimini yazın."
                }
              ]
            }
          }
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
          ],
          "translations": {
            "az": {
              "questions": [
                {
                  "questionText": "Nümunə sual?",
                  "options": ["A", "B", "C", "D"],
                  "explanation": "İzah..."
                }
              ]
            }
          }
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
          "category": "Mindset",
          "translations": {
            "az": {
              "title": "Kiçikdən başla",
              "body": "Məsləhət mətni...",
              "category": "Düşüncə"
            }
          }
        }
      ]
    }
    """
}

struct LessonContentBlockDraft: Identifiable {
    let id = UUID()
    var kind: LessonContentBlockKind = .section
    var title: String = ""
    var text: String = ""
    var itemsText: String = ""
    var titleAZ: String = ""
    var textAZ: String = ""
    var itemsTextAZ: String = ""
    var titleRU: String = ""
    var textRU: String = ""
    var itemsTextRU: String = ""

    var builtBlock: LessonContentBlock? {
        let cleanTitle = title.adminCleanedText
        let cleanText = text.adminCleanedText
        let cleanItems = itemsText
            .split(separator: "\n")
            .map { String($0).adminCleanedText }
            .filter { !$0.isEmpty }

        guard !cleanTitle.isEmpty || !cleanText.isEmpty || !cleanItems.isEmpty else {
            return nil
        }

        return LessonContentBlock(
            id: UUID().uuidString,
            kind: kind,
            title: cleanTitle,
            text: cleanText,
            items: cleanItems
        )
    }

    func builtBlock(for language: AppLanguage) -> LessonContentBlock? {
        let localizedTitle: String
        let localizedText: String
        let localizedItemsText: String

        switch language {
        case .en:
            localizedTitle = title
            localizedText = text
            localizedItemsText = itemsText
        case .az:
            localizedTitle = titleAZ
            localizedText = textAZ
            localizedItemsText = itemsTextAZ
        case .ru:
            localizedTitle = titleRU
            localizedText = textRU
            localizedItemsText = itemsTextRU
        }

        let cleanTitle = localizedTitle.adminCleanedText
        let cleanText = localizedText.adminCleanedText
        let cleanItems = localizedItemsText
            .split(separator: "\n")
            .map { String($0).adminCleanedText }
            .filter { !$0.isEmpty }

        guard !cleanTitle.isEmpty || !cleanText.isEmpty || !cleanItems.isEmpty else {
            return nil
        }

        return LessonContentBlock(
            id: UUID().uuidString,
            kind: kind,
            title: cleanTitle,
            text: cleanText,
            items: cleanItems
        )
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
    var questionTextAZ: String = ""
    var optionsAZ: [String] = ["", "", "", ""]
    var explanationAZ: String = ""
    var questionTextRU: String = ""
    var optionsRU: [String] = ["", "", "", ""]
    var explanationRU: String = ""

    var isValid: Bool {
        !questionText.isEmpty &&
        options.filter { !$0.isEmpty }.count == 4 &&
        !explanation.isEmpty
    }

    func hasTranslation(for language: AppLanguage, baseQuestion: QuizQuestion) -> Bool {
        let payload = translationPayload(for: language, baseQuestion: baseQuestion)
        return !payload.questionText.isEmpty ||
            payload.options.contains(where: { !$0.isEmpty }) ||
            !payload.explanation.isEmpty
    }

    func translationPayload(
        for language: AppLanguage,
        baseQuestion: QuizQuestion
    ) -> QuizQuestionTranslationPayload {
        let localizedQuestionText: String
        let localizedOptions: [String]
        let localizedExplanation: String

        switch language {
        case .en:
            localizedQuestionText = questionText
            localizedOptions = options
            localizedExplanation = explanation
        case .az:
            localizedQuestionText = questionTextAZ
            localizedOptions = optionsAZ
            localizedExplanation = explanationAZ
        case .ru:
            localizedQuestionText = questionTextRU
            localizedOptions = optionsRU
            localizedExplanation = explanationRU
        }

        return QuizQuestionTranslationPayload(
            id: baseQuestion.id,
            questionText: localizedQuestionText.adminCleanedText,
            type: baseQuestion.type,
            options: localizedOptions.map(\.adminCleanedText),
            explanation: localizedExplanation.adminCleanedText
        )
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
    let weekNumber: Int?
    let title: String?
    let description: String?
    let isPublished: Bool?
    let translations: BulkWeekTranslationsImport?
}

private struct BulkLessonImport: Decodable {
    let alias: String?
    let id: String?
    let weekNumber: Int?
    let dayNumber: Int?
    let category: String?
    let title: String?
    let contentMode: LessonContentMode?
    let body: String?
    let blocks: [BulkLessonContentBlockImport]?
    let difficultyLevel: String?
    let translations: BulkLessonTranslationsImport?
}

private struct BulkLessonContentBlockImport: Decodable {
    let id: String?
    let kind: LessonContentBlockKind?
    let title: String?
    let text: String?
    let items: [String]?
}

private struct BulkQuizImport: Decodable {
    let alias: String?
    let id: String?
    let weekNumber: Int?
    let dayNumber: Int?
    let questions: [BulkQuizQuestionImport]?
    let translations: BulkQuizTranslationsImport?
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
    let title: String?
    let body: String?
    let date: String?
    let category: String?
    let translations: BulkDailyTipTranslationsImport?
}

private struct BulkWeekTranslationsImport: Decodable {
    let az: BulkWeekTranslationImport?
    let ru: BulkWeekTranslationImport?
}

private struct BulkWeekTranslationImport: Decodable {
    let title: String?
    let description: String?
}

private struct BulkLessonTranslationsImport: Decodable {
    let az: BulkLessonTranslationImport?
    let ru: BulkLessonTranslationImport?
}

private struct BulkLessonTranslationImport: Decodable {
    let category: String?
    let title: String?
    let body: String?
    let blocks: [BulkLessonContentBlockImport]?
}

private struct BulkQuizTranslationsImport: Decodable {
    let az: BulkQuizTranslationImport?
    let ru: BulkQuizTranslationImport?
}

private struct BulkQuizTranslationImport: Decodable {
    let questions: [BulkQuizQuestionTranslationImport]
}

private struct BulkQuizQuestionTranslationImport: Decodable {
    let questionText: String?
    let type: String?
    let options: [String]?
    let explanation: String?
}

private struct BulkDailyTipTranslationsImport: Decodable {
    let az: BulkDailyTipTranslationImport?
    let ru: BulkDailyTipTranslationImport?
}

private struct BulkDailyTipTranslationImport: Decodable {
    let title: String?
    let body: String?
    let category: String?
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

private extension String {
    var adminCleanedText: String {
        replacingOccurrences(of: "\u{00A0}", with: " ")
            .replacingOccurrences(of: "\u{2028}", with: "\n")
            .replacingOccurrences(of: "\u{2029}", with: "\n")
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
