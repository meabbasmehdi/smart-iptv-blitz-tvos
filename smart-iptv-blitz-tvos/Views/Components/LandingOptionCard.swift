import SwiftUI

struct LandingOptionCard: View {
    let title: String
    let subtitle: String
    let imageName: String
    let action: () -> Void

    var body: some View {
        FocusablePressable(action: action) { isFocused in
            VStack(spacing: 8) {
                Image(imageName)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.white)
                    .frame(width: 72, height: 72)

                Text(title)
                    .font(.app(size: 20, weight: .semibold))
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.app(size: 14, weight: .regular))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(height: 40, alignment: .top)
            }
            .frame(width: 220, height: 250)
            .padding(.horizontal, 18)
            .padding(.vertical, 20)
            .background(isFocused ? AppColors.focusedCardBackground : AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isFocused ? AppColors.brandSecondary : .clear, lineWidth: 3)
            )
            .scaleEffect(isFocused ? 1.04 : 1)
            .animation(.easeOut(duration: 0.14), value: isFocused)
        }
    }
}
