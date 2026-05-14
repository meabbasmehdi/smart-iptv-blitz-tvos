import SwiftUI

struct FocusablePressable<Content: View>: View {
    let action: () -> Void
    let content: (Bool) -> Content

    @FocusState private var isFocused: Bool

    init(
        action: @escaping () -> Void,
        @ViewBuilder content: @escaping (Bool) -> Content
    ) {
        self.action = action
        self.content = content
    }

    var body: some View {
        content(isFocused)
            .contentShape(Rectangle())
            .focusable(true)
            .focusEffectDisabled()
            .focused($isFocused)
            .onTapGesture(perform: action)
            .accessibilityAddTraits(.isButton)
    }
}
