//
//  AdaptiveChips.swift
//  FinaLit
//

import SwiftUI

struct AdaptiveChips: View {
    let items: [String]
    let selection: String
    let onTap: (String) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 8)], spacing: 8) {
            ForEach(items, id: \.self) { item in
                ChipButton(
                    title: item,
                    icon: "",
                    isSelected: selection == item,
                    onTap: { onTap(item) }
                )
            }
        }
    }
}
