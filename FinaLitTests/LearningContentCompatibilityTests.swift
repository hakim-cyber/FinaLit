import XCTest
@testable import FinaLit

final class LearningContentCompatibilityTests: XCTestCase {
    func testUserDecodesWithoutPreferences() throws {
        let json = """
        {
          "email": "user@example.com",
          "name": "Test User",
          "createdAt": "2026-04-11T00:00:00Z"
        }
        """

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let user = try decoder.decode(User.self, from: Data(json.utf8))
        XCTAssertNil(user.preferences)
    }

    func testLessonDecodesWithoutTranslations() throws {
        let json = """
        {
          "weekNumber": 1,
          "dayNumber": 1,
          "category": "Budgeting",
          "title": "Opportunity Cost",
          "difficultyLevel": "Beginner",
          "contentMode": "article",
          "body": "Base lesson text",
          "blocks": []
        }
        """

        let lesson = try JSONDecoder().decode(Lesson.self, from: Data(json.utf8))
        XCTAssertNil(lesson.translations)
        XCTAssertEqual(lesson.title, "Opportunity Cost")
    }

    func testWeekFallsBackToBaseWhenRequestedTranslationMissing() {
        let week = Week(
            id: "week-1",
            weekNumber: 1,
            title: "Week 1",
            description: "Base description",
            isPublished: true,
            translations: LocalizedContent(
                az: WeekTranslationPayload(
                    title: "1-ci həftə",
                    description: ""
                )
            )
        )

        let resolved = week.resolved(for: .ru)

        XCTAssertEqual(resolved.title, "Week 1")
        XCTAssertEqual(resolved.description, "Base description")
    }

    func testLessonUsesLocalizedFieldsAndFallsBackPerField() {
        let lesson = Lesson(
            id: "lesson-1",
            weekNumber: 1,
            dayNumber: 1,
            category: "Budgeting",
            title: "Opportunity Cost",
            difficultyLevel: DifficultyLevel.beginner.rawValue,
            contentMode: .article,
            body: "Base body",
            blocks: [],
            translations: LocalizedContent(
                az: LessonTranslationPayload(
                    category: "Büdcə",
                    title: "",
                    body: "AZ body",
                    blocks: []
                )
            )
        )

        let resolved = lesson.resolved(for: .az)

        XCTAssertEqual(resolved.category, "Büdcə")
        XCTAssertEqual(resolved.title, "Opportunity Cost")
        XCTAssertEqual(resolved.body, "AZ body")
    }

    func testQuizResolutionPreservesQuestionIDsAndBaseOrder() {
        let questions = [
            QuizQuestion(
                id: "q1",
                questionText: "Base 1",
                type: "multipleChoice",
                options: ["A1", "B1", "C1", "D1"],
                correctIndex: 0,
                explanation: "Base exp 1"
            ),
            QuizQuestion(
                id: "q2",
                questionText: "Base 2",
                type: "multipleChoice",
                options: ["A2", "B2", "C2", "D2"],
                correctIndex: 1,
                explanation: "Base exp 2"
            ),
        ]

        let quiz = Quiz(
            id: "quiz-1",
            weekNumber: 1,
            dayNumber: 1,
            questions: questions,
            translations: LocalizedContent(
                az: QuizTranslationPayload(
                    questions: [
                        QuizQuestionTranslationPayload(
                            id: "q2",
                            questionText: "AZ 2",
                            type: "multipleChoice",
                            options: ["A2 az", "B2 az", "C2 az", "D2 az"],
                            explanation: "AZ exp 2"
                        ),
                        QuizQuestionTranslationPayload(
                            id: "q1",
                            questionText: "AZ 1",
                            type: "multipleChoice",
                            options: ["A1 az", "B1 az", "C1 az", "D1 az"],
                            explanation: "AZ exp 1"
                        ),
                    ]
                )
            )
        )

        let resolved = quiz.resolved(for: .az)

        XCTAssertEqual(resolved.questions.map(\.id), ["q1", "q2"])
        XCTAssertEqual(resolved.questions.map(\.questionText), ["AZ 1", "AZ 2"])
        XCTAssertEqual(resolved.questions[0].correctIndex, 0)
        XCTAssertEqual(resolved.questions[1].correctIndex, 1)
    }

    func testQuizFallsBackWhenTranslationQuestionCountDoesNotMatchBase() {
        let quiz = Quiz(
            id: "quiz-1",
            weekNumber: 1,
            dayNumber: 1,
            questions: [
                QuizQuestion(
                    id: "q1",
                    questionText: "Base 1",
                    type: "multipleChoice",
                    options: ["A", "B", "C", "D"],
                    correctIndex: 0,
                    explanation: "Base"
                ),
                QuizQuestion(
                    id: "q2",
                    questionText: "Base 2",
                    type: "multipleChoice",
                    options: ["A", "B", "C", "D"],
                    correctIndex: 1,
                    explanation: "Base"
                ),
            ],
            translations: LocalizedContent(
                ru: QuizTranslationPayload(
                    questions: [
                        QuizQuestionTranslationPayload(
                            id: "q1",
                            questionText: "RU 1",
                            type: "multipleChoice",
                            options: ["A", "B", "C", "D"],
                            explanation: "RU"
                        )
                    ]
                )
            )
        )

        let resolved = quiz.resolved(for: .ru)

        XCTAssertEqual(resolved.questions.map(\.questionText), ["Base 1", "Base 2"])
    }

    func testLearningLanguageFallsBackToLegacyLanguage() {
        let legacyPreferences = UserPreferences(legacyLanguage: .ru, learningContentLanguage: nil)
        XCTAssertEqual(legacyPreferences.effectiveLearningLanguage(), .ru)

        let explicitPreferences = UserPreferences(legacyLanguage: .az, learningContentLanguage: .en)
        XCTAssertEqual(explicitPreferences.effectiveLearningLanguage(), .en)

        let emptyPreferences = UserPreferences(legacyLanguage: nil, learningContentLanguage: nil)
        XCTAssertEqual(emptyPreferences.effectiveLearningLanguage(), .default)
    }
}
