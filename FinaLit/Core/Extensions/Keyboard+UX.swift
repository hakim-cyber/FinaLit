import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum KeyboardUX {
    static func dismiss() {
#if canImport(UIKit)
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
#endif
    }
}

private struct KeyboardDoneToolbarModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    KeyboardUX.dismiss()
                }
            }
        }
    }
}

extension View {
    func keyboardDoneToolbar() -> some View {
        modifier(KeyboardDoneToolbarModifier())
    }
}
