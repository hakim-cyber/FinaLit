import SwiftUI

private struct ConditionalGlassEffectModifier: ViewModifier {
    var backgroundEnable: Bool = false
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect()
        } else {
            if backgroundEnable{
                content
                    .background(.ultraThinMaterial)
            }else{
                content
            }
        }
    }
}

extension View {
    func glassEffectIfAvailable(backgroundEnabled: Bool = false) -> some View {
        modifier(ConditionalGlassEffectModifier(backgroundEnable: backgroundEnabled))
    }
}
