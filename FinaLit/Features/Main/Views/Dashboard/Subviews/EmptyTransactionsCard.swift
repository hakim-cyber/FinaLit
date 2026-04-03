//
//  EmptyTransactionsCard.swift
//  FinaLit
//

import SwiftUI

struct EmptyTransactionsCard: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("💸")
                .font(.system(size: 36))
            Text("No transactions yet")
                .font(.system(size: 16))
                .foregroundStyle(.white)
            Text("Tap + to add your first transaction")
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: "4B5563"))
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(Color(hex: "111118"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
