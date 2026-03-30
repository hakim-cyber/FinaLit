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

    func normalizedQuestionIDs() -> Quiz {
        var copy = self
        copy.questions = questions.enumerated().map { index, question in
            question.withResolvedID(
                fallback: "w\(weekNumber)-d\(dayNumber)-q\(index + 1)"
            )
        }
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
