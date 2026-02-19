//
//  LearnPages.swift
//  FinaLit
//
//  Created by aplle on 2/18/26.
//


// LearnPages.swift
// Features/Learn/Navigation/


// LearnPages.swift
// Features/Learn/Navigation/

import SwiftUI

enum LearnPages: Coordinatable {
    case home
    case weekDetail(String)              // weekID
    case lessonDetail(String, String)    // lessonID, dayID, weekID handled via env
    case quiz(String, String, String)    // quizID, dayID, weekID
    case quizReview(String, String)      // dayID, weekID
    case reflection(String, String)      // weekID, weekTitle
    case progress

    var id: String {
        switch self {
        case .home:                              return "learn.home"
        case .weekDetail(let id):                return "learn.week.\(id)"
        case .lessonDetail(let l, let d):        return "learn.lesson.\(l).\(d)"
        case .quiz(let q, let d, let w):         return "learn.quiz.\(q).\(d).\(w)"
        case .quizReview(let d, let w):          return "learn.quizReview.\(d).\(w)"
        case .reflection(let w, _):              return "learn.reflection.\(w)"
        case .progress:                          return "learn.progress"
        }
    }

    @ViewBuilder
    var body: some View {
        switch self {
        case .home:
            LearnHomeView()
        case .weekDetail(let weekID):
            WeekDetailView(weekID: weekID)
        case .lessonDetail(let lessonID, let dayID):
            LessonDetailView(lessonID: lessonID, dayID: dayID)
        case .quiz(let quizID, let dayID, let weekID):
            QuizView(quizID: quizID, dayID: dayID, weekID: weekID)
        case .quizReview(let dayID, let weekID):
            QuizReviewView(dayID: dayID, weekID: weekID)
        case .reflection(let weekID, let weekTitle):
            ReflectionView(weekID: weekID, weekTitle: weekTitle)
        case .progress:
            LearningProgressView()
        }
    }
}
