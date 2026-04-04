//
//  MoneySlider.swift
//  FinaLit
//

import SwiftUI

struct MoneySlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(OnboardingPalette.muted)
                Spacer()
                Text(currency(snapped(value)))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
            }

            Slider(value: $value, in: range, step: step)
                .tint(tint)
        }
        .padding(14)
        .background(OnboardingPalette.surface, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(OnboardingPalette.border, lineWidth: 1)
        )
        .onAppear {
            let adjusted = snapped(value)
            if abs(adjusted - value) > 0.0001 {
                value = adjusted
            }
        }
        .onChange(of: value) { _, newValue in
            let adjusted = snapped(newValue)
            if abs(adjusted - newValue) > 0.0001 {
                value = adjusted
            }
        }
    }

    private func snapped(_ raw: Double) -> Double {
        guard step > 0 else { return raw }
        let snappedValue = (raw / step).rounded() * step
        return min(max(snappedValue, range.lowerBound), range.upperBound)
    }
}
