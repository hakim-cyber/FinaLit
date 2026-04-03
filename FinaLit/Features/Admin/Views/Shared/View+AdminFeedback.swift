//
//  View+AdminFeedback.swift
//  FinaLit
//

import SwiftUI

extension View {
    func adminFeedback(success: String?, error: String?, onDismiss: @escaping () -> Void) -> some View {
        self
            .alert("Success ✓", isPresented: .constant(success != nil)) {
                Button("OK", action: onDismiss)
            } message: {
                Text(success ?? "")
            }
            .alert("Error", isPresented: .constant(error != nil)) {
                Button("OK", action: onDismiss)
            } message: {
                Text(error ?? "")
            }
    }
}
