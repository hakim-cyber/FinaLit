//
//  AdminHomeView.swift
//  FinaLit
//

import SwiftUI

struct AdminHomeView: View {
    @Environment(Coordinator<AdminPages>.self) private var coordinator

    var body: some View {
        ZStack {
            Color(hex: "0A0A0F").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    AdminSection(title: "LEARNING CONTENT") {
                        AdminMenuRow(
                            icon: "calendar.badge.plus",
                            title: "Add Week",
                            subtitle: "Create a new learning week",
                            color: "6366F1"
                        ) { coordinator.push(.addWeek) }

                        AdminMenuRow(
                            icon: "plus.circle",
                            title: "Add Day to Week",
                            subtitle: "Add a day inside an existing week",
                            color: "8B5CF6"
                        ) { coordinator.push(.addDay("")) }

                        AdminMenuRow(
                            icon: "book.fill",
                            title: "Add Lesson",
                            subtitle: "Create lesson content for a day",
                            color: "06B6D4"
                        ) { coordinator.push(.addLesson("")) }

                        AdminMenuRow(
                            icon: "questionmark.circle.fill",
                            title: "Add Quiz",
                            subtitle: "Create a quiz with questions",
                            color: "FACC15"
                        ) { coordinator.push(.addQuiz("")) }

                        AdminMenuRow(
                            icon: "doc.text.fill",
                            title: "Bulk JSON Import",
                            subtitle: "Paste one JSON payload to create everything",
                            color: "22D3EE"
                        ) { coordinator.push(.bulkImport) }
                    }

                    AdminSection(title: "DAILY TIPS") {
                        AdminMenuRow(
                            icon: "lightbulb.fill",
                            title: "Add Daily Tip",
                            subtitle: "Upload a daily insight for users",
                            color: "10B981"
                        ) { coordinator.push(.addDailyTip) }
                    }

                    Spacer(minLength: 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    coordinator.push(.settings, type: .fullScreenCover)
                } label: {
                    Image(systemName: "gearshape")
                        .foregroundStyle(Color.primary)
                }
            }
        }
        .toolbarBackground(.visible, for: .navigationBar)
    }
}
