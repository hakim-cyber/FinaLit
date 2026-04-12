//
//  View+AdminFeedback.swift
//  FinaLit
//

import SwiftUI

extension View {
    func adminFeedback(success: String?, error: String?, onDismiss: @escaping () -> Void) -> some View {
        self
            .alert(L10n.Admin.success, isPresented: .constant(success != nil)) {
                Button(L10n.Auth.ok, action: onDismiss)
            } message: {
                Text(success ?? "")
            }
            .alert(L10n.Admin.error, isPresented: .constant(error != nil)) {
                Button(L10n.Auth.ok, action: onDismiss)
            } message: {
                Text(error ?? "")
            }
    }
}
