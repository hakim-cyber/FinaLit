//
//  LessonContentBlockDraftCard.swift
//  FinaLit
//

import SwiftUI

struct LessonContentBlockDraftCard: View {
    let index: Int
    @Environment(AdminViewModel.self) private var adminVM

    var body: some View {
        if adminVM.lessonBlocks.indices.contains(index) {
            let kindBinding = Binding<LessonContentBlockKind>(
                get: { adminVM.lessonBlocks[index].kind },
                set: { adminVM.lessonBlocks[index].kind = $0 }
            )
            let titleBinding = Binding<String>(
                get: { adminVM.lessonBlocks[index].title },
                set: { adminVM.lessonBlocks[index].title = $0 }
            )
            let textBinding = Binding<String>(
                get: { adminVM.lessonBlocks[index].text },
                set: { adminVM.lessonBlocks[index].text = $0 }
            )
            let itemsBinding = Binding<String>(
                get: { adminVM.lessonBlocks[index].itemsText },
                set: { adminVM.lessonBlocks[index].itemsText = $0 }
            )
            let azTitleBinding = Binding<String>(
                get: { adminVM.lessonBlocks[index].titleAZ },
                set: { adminVM.lessonBlocks[index].titleAZ = $0 }
            )
            let azTextBinding = Binding<String>(
                get: { adminVM.lessonBlocks[index].textAZ },
                set: { adminVM.lessonBlocks[index].textAZ = $0 }
            )
            let azItemsBinding = Binding<String>(
                get: { adminVM.lessonBlocks[index].itemsTextAZ },
                set: { adminVM.lessonBlocks[index].itemsTextAZ = $0 }
            )
            let ruTitleBinding = Binding<String>(
                get: { adminVM.lessonBlocks[index].titleRU },
                set: { adminVM.lessonBlocks[index].titleRU = $0 }
            )
            let ruTextBinding = Binding<String>(
                get: { adminVM.lessonBlocks[index].textRU },
                set: { adminVM.lessonBlocks[index].textRU = $0 }
            )
            let ruItemsBinding = Binding<String>(
                get: { adminVM.lessonBlocks[index].itemsTextRU },
                set: { adminVM.lessonBlocks[index].itemsTextRU = $0 }
            )

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("BLOCK \(String(format: "%02d", index + 1))")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color(hex: "6366F1"))
                    Spacer()
                    Button(role: .destructive) {
                        adminVM.removeLessonBlock(at: index)
                    } label: {
                        Label(L10n.Admin.remove, systemImage: "trash")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: "F87171"))
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.Admin.kind)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color(hex: "4B5563"))
                    Picker(L10n.Admin.blockKind, selection: kindBinding) {
                        ForEach(LessonContentBlockKind.allCases) {
                            Text($0.label).tag($0)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.white)
                }

                AdminField(label: "TITLE (OPTIONAL)", placeholder: "Personal Budget", text: titleBinding)

                if kindBinding.wrappedValue.usesItems {
                    AdminTextArea(
                        label: "ITEMS (ONE PER LINE)",
                        placeholder: "First point\nSecond point\nThird point",
                        text: itemsBinding,
                        minHeight: 120
                    )
                } else {
                    AdminTextArea(
                        label: "TEXT",
                        placeholder: "Write the block content here...",
                        text: textBinding,
                        minHeight: 150
                    )
                }

                AdminTranslationSection(title: "AZERBAIJANI TRANSLATION (OPTIONAL)") {
                    AdminField(label: "TITLE (AZ)", placeholder: "Başlıq", text: azTitleBinding)
                    if kindBinding.wrappedValue.usesItems {
                        AdminTextArea(
                            label: "ITEMS (AZ)",
                            placeholder: "Birinci bənd\nİkinci bənd",
                            text: azItemsBinding,
                            minHeight: 100
                        )
                    } else {
                        AdminTextArea(
                            label: "TEXT (AZ)",
                            placeholder: "Blok məzmunu...",
                            text: azTextBinding,
                            minHeight: 120
                        )
                    }
                }

                AdminTranslationSection(title: "RUSSIAN TRANSLATION (OPTIONAL)") {
                    AdminField(label: "TITLE (RU)", placeholder: "Заголовок", text: ruTitleBinding)
                    if kindBinding.wrappedValue.usesItems {
                        AdminTextArea(
                            label: "ITEMS (RU)",
                            placeholder: "Первый пункт\nВторой пункт",
                            text: ruItemsBinding,
                            minHeight: 100
                        )
                    } else {
                        AdminTextArea(
                            label: "TEXT (RU)",
                            placeholder: "Содержимое блока...",
                            text: ruTextBinding,
                            minHeight: 120
                        )
                    }
                }
            }
            .padding(14)
            .background(Color(hex: "111118"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "1F2937"), lineWidth: 1)
            )
        }
    }
}
