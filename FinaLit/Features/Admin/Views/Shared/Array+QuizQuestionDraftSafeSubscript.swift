//
//  Array+QuizQuestionDraftSafeSubscript.swift
//  FinaLit
//

import Foundation

extension Array where Element == QuizQuestionDraft {
    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
}
