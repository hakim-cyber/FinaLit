//
//  OnboardingHobbiesView.swift
//  FinaLit
//

import SwiftUI

struct OnboardingHobbiesView: View {
    @Environment(OnboardingViewModel.self) private var viewModel
    @Environment(Coordinator<OnboardingPages>.self) private var coordinator

    private let hobbies = [
        "Gaming 🎮", "Music 🎵", "Cooking 🍳", "Fitness 💪",
        "Reading 📚", "Travel ✈️", "Photography 📷", "Fashion 👗",
        "Movies 🎬", "Sports ⚽", "Art 🎨", "Other ✏️"
    ]

    var body: some View {
        @Bindable var viewModel = viewModel

        OnboardingStepScaffold(
            page: .hobbies,
            title: "What do you enjoy outside money?",
            subtitle: "Choose up to \(viewModel.maxHobbySelections), or add your own.",
            errorMessage: viewModel.errorMessage,
            isLoading: viewModel.isLoading,
            primaryTitle: String(localized: "profile.continueAction"),
            isPrimaryEnabled: viewModel.isStep11Valid,
            onPrimaryTap: {
                if viewModel.validateStep11Hobbies() {
                    coordinator.push(.knowledgeLevel)
                }
            }
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text("\(viewModel.normalizedHobbies.count)/\(viewModel.maxHobbySelections) selected")
                    .font(.system(size: 11))
                    .foregroundStyle(OnboardingPalette.muted)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 10)], spacing: 10) {
                    ForEach(hobbies, id: \.self) { hobby in
                        if hobby == "Other ✏️" {
                            ChipButton(
                                title: hobby,
                                icon: "",
                                isSelected: viewModel.isOtherHobbySelected,
                                onTap: {
                                    viewModel.isOtherHobbySelected.toggle()
                                    if !viewModel.isOtherHobbySelected {
                                        viewModel.customHobby = ""
                                    }
                                    viewModel.clearError()
                                }
                            )
                        } else {
                            ChipButton(
                                title: hobby,
                                icon: "",
                                isSelected: viewModel.selectedHobbies.contains(hobby),
                                onTap: { viewModel.toggleHobby(hobby) }
                            )
                        }
                    }
                }

                if viewModel.isOtherHobbySelected {
                    TextField(L10n.Onboarding.addCustomHobby, text: $viewModel.customHobby)
                        .textInputAutocapitalization(.words)
                        .onboardingInputStyle()
                        .onChange(of: viewModel.customHobby) { _, _ in
                            viewModel.clearError()
                        }
                }
            }
        }
    }
}
