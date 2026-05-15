import SwiftUI

struct SplashView: View {
    let showStartButton: Bool
    let onStartClick: (() -> Void)?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if !showStartButton {
                Image(AppImages.splashBackground)
                    .resizable()
                    .aspectRatio(16 / 9, contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .ignoresSafeArea()
            }

            if showStartButton, let onStartClick {
                FocusableActionButton(
                    title: "Start",
                    background: AppColors.brandPrimary,
                    focusedBackground: AppColors.brandPrimary.opacity(0.9),
                    border: .clear,
                    width: 220,
                    height: 64,
                    action: onStartClick
                )
            }
        }
    }
}
