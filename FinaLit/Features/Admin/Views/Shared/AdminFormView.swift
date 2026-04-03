//
//  AdminFormView.swift
//  FinaLit
//

import SwiftUI

struct AdminFormView<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            Color(hex: "0A0A0F").ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 10) {
                        Image(systemName: icon)
                            .foregroundStyle(Color(hex: "6366F1"))
                        Text(title)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(.white)
                    }
                    .padding(.top, 8)

                    content

                    Spacer(minLength: 40)
                }
                .padding(20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
