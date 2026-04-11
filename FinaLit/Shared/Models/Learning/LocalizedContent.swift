//
//  LocalizedContent.swift
//  FinaLit
//

import Foundation

struct LocalizedContent<Value: Codable>: Codable {
    var az: Value?
    var ru: Value?

    init(az: Value? = nil, ru: Value? = nil) {
        self.az = az
        self.ru = ru
    }

    func value(for language: AppLanguage) -> Value? {
        switch language {
        case .en:
            return nil
        case .az:
            return az
        case .ru:
            return ru
        }
    }
}

struct WeekTranslationPayload: Codable {
    var title: String = ""
    var description: String = ""
}

struct DailyTipTranslationPayload: Codable {
    var title: String = ""
    var body: String = ""
    var category: String = ""
}

struct LessonTranslationPayload: Codable {
    var category: String = ""
    var title: String = ""
    var body: String = ""
    var blocks: [LessonContentBlock] = []
}

struct QuizQuestionTranslationPayload: Codable, Identifiable {
    var id: String = ""
    var questionText: String = ""
    var type: String = ""
    var options: [String] = []
    var explanation: String = ""
}

struct QuizTranslationPayload: Codable {
    var questions: [QuizQuestionTranslationPayload] = []
}
