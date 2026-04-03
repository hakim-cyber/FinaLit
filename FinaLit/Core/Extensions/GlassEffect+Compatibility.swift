import SwiftUI

private struct ConditionalGlassEffectModifier: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect()
        } else {
            content
        }
    }
}

extension View {
    func glassEffectIfAvailable() -> some View {
        modifier(ConditionalGlassEffectModifier())
    }
}
