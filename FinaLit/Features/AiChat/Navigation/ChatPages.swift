//
//  ChatPages.swift
//  FinaLit
//
//  Created by aplle on 2/18/26.
//


// ChatPages.swift
// Features/Chat/Navigation/

import SwiftUI

enum ChatPages: Coordinatable {

    case chat
    // ── Add new chat pages here ────────────────────────────────
    // case adviceDetail(String)    // messageID

    // MARK: - Identifiable
    var id: String {
        switch self {
        case .chat: return "chat.main"
        }
    }

    // MARK: - View
    @ViewBuilder
    var body: some View {
        switch self {
        case .chat: ChatView()
        }
    }
}
