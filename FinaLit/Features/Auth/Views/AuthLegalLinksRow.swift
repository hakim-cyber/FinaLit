//
//  AuthLegalLinksRow.swift
//  FinaLit
//

import SwiftUI

struct AuthLegalLinksRow: View {
    private var hasAnyLink: Bool {
        AppLegalLinks.privacyPolicyURL != nil || AppLegalLinks.termsOfUseURL != nil
    }

    var body: some View {
        if hasAnyLink {
            HStack(spacing: 16) {
                if let privacyPolicyURL = AppLegalLinks.privacyPolicyURL {
                    Link("Privacy Policy", destination: privacyPolicyURL)
                }

                if let termsOfUseURL = AppLegalLinks.termsOfUseURL {
                    Link("Terms of Use", destination: termsOfUseURL)
                }
            }
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(AppTheme.textSecondary)
            .tint(AppTheme.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.top, 2)
        }
    }
}
