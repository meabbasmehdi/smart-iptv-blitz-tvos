import SwiftUI

struct HomeScreen: View {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        PlaylistLandingBackground {
            VStack(spacing: 0) {
                topBar
                Spacer()

                HStack(spacing: 24) {
                    HomeCategoryCard(title: "Live TV", subtitle: "Last Updated today\n0+ channels", iconName: "tv")
                    HomeCategoryCard(title: "Movies", subtitle: "Last Updated today\n0+ Movies", iconName: "film")
                    HomeCategoryCard(title: "Series", subtitle: "Last Updated today\n0+ Series", iconName: "rectangle.stack")
                    Spacer().frame(maxWidth: .infinity)
                }
                .padding(.bottom, 64)
            }
            .padding(.horizontal, 48)
            .padding(.vertical, 40)
        }
    }

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Smart IPTV")
                    .font(.app(size: 32, weight: .bold))
                    .foregroundStyle(.white)
                Text(viewModel.activePlaylistTitle)
                    .font(.app(size: 15, weight: .regular))
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()

            HStack(spacing: 8) {
                TopBarButton(title: "Get Pro", iconName: "crown")
                TopBarButton(title: "Manage", iconName: "list.bullet.rectangle")
                TopBarButton(title: "Favorites", iconName: "heart")
                TopBarButton(title: "Settings", iconName: "gearshape")
                ClockView()
            }
        }
    }
}

private struct TopBarButton: View {
    let title: String
    let iconName: String

    var body: some View {
        FocusablePressable(action: {}) { isFocused in
            HStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.app(size: 14, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .frame(height: 40)
            .background(isFocused ? AppColors.brandSecondary : .clear)
            .clipShape(Capsule())
        }
    }
}

private struct HomeCategoryCard: View {
    let title: String
    let subtitle: String
    let iconName: String

    var body: some View {
        FocusablePressable(action: {}) { isFocused in
            VStack(alignment: .leading, spacing: 18) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.white.opacity(0.16))
                    Image(systemName: iconName)
                        .font(.system(size: 58, weight: .regular))
                        .foregroundStyle(.white.opacity(0.82))
                }
                .frame(height: 180)

                Text(title)
                    .font(.app(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.app(size: 15, weight: .regular))
                    .foregroundStyle(.white.opacity(0.76))
                    .lineSpacing(3)
            }
            .padding(20)
            .frame(width: 300, height: 330, alignment: .topLeading)
            .background(.black.opacity(isFocused ? 0.32 : 0.18))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isFocused ? AppColors.brandSecondary : .white.opacity(0.12), lineWidth: isFocused ? 3 : 1)
            )
            .scaleEffect(isFocused ? 1.04 : 1)
            .animation(.easeOut(duration: 0.14), value: isFocused)
        }
    }
}
