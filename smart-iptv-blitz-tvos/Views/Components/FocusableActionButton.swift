import SwiftUI

struct FocusableActionButton: View {
    let title: String
    let background: Color
    let focusedBackground: Color
    let border: Color
    let focusedBorder: Color
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat
    let action: () -> Void

    init(
        title: String,
        background: Color,
        focusedBackground: Color? = nil,
        border: Color = .white.opacity(0.22),
        focusedBorder: Color = AppColors.brandSecondary,
        width: CGFloat = 240,
        height: CGFloat = 60,
        cornerRadius: CGFloat? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.background = background
        self.focusedBackground = focusedBackground ?? background.opacity(0.9)
        self.border = border
        self.focusedBorder = focusedBorder
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius ?? (height > 50 ? 30 : 24)
        self.action = action
    }

    var body: some View {
        FocusablePressable(action: action) { isFocused in
            Text(title)
                .font(.app(size: fontSize, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: width, height: height)
                .background(isFocused ? focusedBackground : background)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(isFocused ? focusedBorder : border, lineWidth: isFocused ? 2.5 : 1)
                )
                .scaleEffect(isFocused ? 1.02 : 1.0)
                .animation(.easeOut(duration: 0.14), value: isFocused)
        }
    }

    private var fontSize: CGFloat {
        if height < 48 {
            return 14
        } else if height < 54 {
            return 16
        } else if height < 60 {
            return 18
        } else {
            return 20
        }
    }
}
