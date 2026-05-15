import SwiftUI

struct PlaylistGateScreen: View {
    @ObservedObject var viewModel: PlaylistsViewModel
    let onNeedsPlaylistCreation: () -> Void
    let onOpenHome: () -> Void

    var body: some View {
        PlaylistLandingBackground {
            ZStack {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.4)
                } else if !viewModel.playlists.isEmpty {
                    PlaylistSelectionView(
                        playlists: viewModel.playlists,
                        onSelectPlaylist: { playlist in
                            viewModel.selectPlaylist(playlist)
                            onOpenHome()
                        },
                        onAddPlaylist: onNeedsPlaylistCreation
                    )
                } else if let errorMessage = viewModel.errorMessage {
                    VStack(spacing: 18) {
                        Text(errorMessage)
                            .font(.app(size: 18, weight: .medium))
                            .foregroundStyle(.white.opacity(0.85))
                            .multilineTextAlignment(.center)

                        FocusableActionButton(
                            title: "Try Again",
                            background: AppColors.brandPrimary,
                            width: 180,
                            height: 54
                        ) {
                            Task { await viewModel.refresh() }
                        }
                    }
                    .padding(.horizontal, 120)
                }
            }
        }
        .task {
            await viewModel.loadIfNeeded()
        }
        .onChange(of: viewModel.isLoading) { _, isLoading in
            guard !isLoading, viewModel.errorMessage == nil, viewModel.playlists.isEmpty else {
                return
            }
            onNeedsPlaylistCreation()
        }
    }
}

private struct PlaylistSelectionView: View {
    let playlists: [PlaylistResponse]
    let onSelectPlaylist: (PlaylistResponse) -> Void
    let onAddPlaylist: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            HStack {
                Text("Smart IPTV")
                    .font(.app(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
            }
            .padding(.horizontal, 40)

            ScrollView(.horizontal) {
                HStack(spacing: 20) {
                    ForEach(playlists) { playlist in
                        PlaylistCard(playlist: playlist) {
                            onSelectPlaylist(playlist)
                        }
                    }

                    AddPlaylistCard(action: onAddPlaylist)
                }
                .padding(.horizontal, 40)
            }

            Spacer()
        }
        .padding(.vertical, 40)
    }
}

private struct PlaylistCard: View {
    let playlist: PlaylistResponse
    let action: () -> Void

    var body: some View {
        FocusablePressable(action: action) { isFocused in
            VStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(cardGradient(isFocused: isFocused))
                    .frame(width: 200, height: 250)
                    .overlay {
                        Image(systemName: iconName)
                            .font(.system(size: 64, weight: .regular))
                            .foregroundStyle(.white.opacity(0.82))
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(isFocused ? AppColors.brandSecondary : .clear, lineWidth: 3)
                    )

                Text(playlist.title)
                    .font(.app(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(playlist.isActive ? "Active" : "Valid")
                    .font(.app(size: 12, weight: .semibold))
                    .foregroundStyle(playlist.isActive ? AppColors.brandSecondary : .white)
            }
            .frame(width: 200)
            .scaleEffect(isFocused ? 1.04 : 1)
        }
    }

    private func cardGradient(isFocused: Bool) -> LinearGradient {
        LinearGradient(
            colors: [
                AppColors.cardBackground,
                (isFocused ? AppColors.brandSecondary : AppColors.shadowBlack).opacity(0.2)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var iconName: String {
        switch playlist.source {
        case .xtream:
            return "play.rectangle"
        case .m3uLink, .m3uFile:
            return "link"
        default:
            return "rectangle.stack"
        }
    }
}

private struct AddPlaylistCard: View {
    let action: () -> Void

    var body: some View {
        FocusablePressable(action: action) { isFocused in
            VStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                AppColors.cardBackground,
                                (isFocused ? AppColors.brandSecondary : AppColors.shadowBlack).opacity(0.2)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 200, height: 250)
                    .overlay {
                        Image(systemName: "plus")
                            .font(.system(size: 48, weight: .regular))
                            .foregroundStyle(.white)
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(isFocused ? AppColors.brandSecondary : .clear, lineWidth: 3)
                    )

                Text("Add Playlist")
                    .font(.app(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 200)
            .scaleEffect(isFocused ? 1.05 : 1)
        }
    }
}
