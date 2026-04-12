//
//  OnboardingHobbiesView.swift
//  FinaLit
//

import SwiftUI

struct OnboardingHobbiesView: View {
    @Environment(OnboardingViewModel.self) private var viewModel
    @Environment(Coordinator<OnboardingPages>.self) private var coordinator

    private let hobbies = [
        String(localized: "onboarding.hobbyGaming"), String(localized: "onboarding.hobbyMusic"), String(localized: "onboarding.hobbyCooking"), String(localized: "onboarding.hobbyFitness"),
        String(localized: "onboarding.hobbyReading"), String(localized: "onboarding.hobbyTravel"), String(localized: "onboarding.hobbyPhotography"), String(localized: "onboarding.hobbyFashion"),
        String(localized: "onboarding.hobbyMovies"), String(localized: "onboarding.hobbySports"), String(localized: "onboarding.hobbyArt"), String(localized: "onboarding.hobbyOther")
    ]

    var body: some View {
        @Bindable var viewModel = viewModel

        OnboardingStepScaffold(
            page: .hobbies,
            title: String(localized: "onboarding.whatDoYouEnjoy"),
            subtitle: String(format: NSLocalizedString("onboarding.pickUpToHobbies", comment: ""), viewModel.maxHobbySelections),
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
                Text(String(format: NSLocalizedString("onboarding.selectedCount", comment: ""), viewModel.normalizedHobbies.count, viewModel.maxHobbySelections))
                    .font(.system(size: 11))
                    .foregroundStyle(OnboardingPalette.muted)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 10)], spacing: 10) {
                    ForEach(hobbies, id: \.self) { hobby in
                        if hobby == String(localized: "onboarding.hobbyOther") {
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
