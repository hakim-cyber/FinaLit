//
//  Quiz.swift
//  FinaLit
//

import Foundation
import FirebaseFirestore

struct Quiz: Codable,Identifiable  {
    @DocumentID var id: String?
    var weekNumber: Int
    var dayNumber: Int
    var questions: [QuizQuestion]
    var translations: LocalizedContent<QuizTranslationPayload>? = nil

    func normalizedQuestionIDs() -> Quiz {
        var copy = self
        copy.questions = questions.enumerated().map { index, question in
            question.withResolvedID(
                fallback: "w\(weekNumber)-d\(dayNumber)-q\(index + 1)"
            )
        }
        return copy
    }

    func resolved(for language: AppLanguage, fallback: AppLanguage = .en) -> Quiz {
        guard let translation = translations?.value(for: language) ?? translations?.value(for: fallback) else {
            return self
        }

        guard translation.questions.count == questions.count else {
            return self
        }

        let translationByID = Dictionary(uniqueKeysWithValues: translation.questions.map { ($0.id, $0) })
        let translatedQuestions = questions.map { question -> QuizQuestion in
            guard let translated = translationByID[question.id] else {
                return question
            }

            let translatedQuestionText = translated.questionText.trimmingCharacters(in: .whitespacesAndNewlines)
            let translatedType = translated.type.trimmingCharacters(in: .whitespacesAndNewlines)
            let translatedExplanation = translated.explanation.trimmingCharacters(in: .whitespacesAndNewlines)
            let translatedOptions = translated.options.map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
            }

            return QuizQuestion(
                id: question.id,
                questionText: translatedQuestionText.isEmpty ? question.questionText : translatedQuestionText,
                type: translatedType.isEmpty ? question.type : translatedType,
                options: translatedOptions.count == question.options.count && translatedOptions.allSatisfy({ !$0.isEmpty })
                    ? translatedOptions
                    : question.options,
                correctIndex: question.correctIndex,
                explanation: translatedExplanation.isEmpty ? question.explanation : translatedExplanation
            )
        }

        var copy = self
        copy.questions = translatedQuestions
        return copy
    }
}

struct QuizQuestion: Codable,Identifiable  {
    enum CodingKeys: String, CodingKey {
        case id
        case questionText
        case type
        case options
        case correctIndex
        case explanation
    }

    var id: String
    var questionText: String
    var type: String
    var options: [String]
    var correctIndex: Int
    var explanation: String

    init(
        id: String = UUID().uuidString,
        questionText: String,
        type: String,
        options: [String],
        correctIndex: Int,
        explanation: String
    ) {
        self.id = id
        self.questionText = questionText
        self.type = type
        self.options = options
        self.correctIndex = correctIndex
        self.explanation = explanation
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedID = try container.decodeIfPresent(String.self, forKey: .id)?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        id = decodedID.flatMap { $0.isEmpty ? nil : $0 } ?? ""
        questionText = try container.decode(String.self, forKey: .questionText)
        type = try container.decode(String.self, forKey: .type)
        options = try container.decode([String].self, forKey: .options)
        correctIndex = try container.decode(Int.self, forKey: .correctIndex)
        explanation = try container.decode(String.self, forKey: .explanation)
    }

    func withResolvedID(fallback: String) -> QuizQuestion {
        guard id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return self
        }

        var copy = self
        copy.id = fallback
        return copy
    }
}
