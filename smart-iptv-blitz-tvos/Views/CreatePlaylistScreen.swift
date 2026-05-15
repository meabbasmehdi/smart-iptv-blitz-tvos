import SwiftUI

struct CreatePlaylistScreen: View {
    @ObservedObject var viewModel: CreatePlaylistViewModel
    let onDemoPlaylistAdded: () -> Void

    @State private var flow: CreatePlaylistFlow = .landing

    var body: some View {
        switch flow {
        case .landing:
            CreatePlaylistLandingView(
                onCreateXtream: {
                    flow = .xtream
                },
                onCreateM3U: {
                    flow = .m3u
                },
                onOpenDemoPlaylist: {
                    viewModel.clearError()
                    flow = .demo
                }
            )
        case .xtream:
            XtreamPlaylistView {
                flow = .landing
            }
        case .m3u:
            M3UPlaylistView {
                flow = .landing
            }
        case .demo:
            DemoPlaylistView(
                viewModel: viewModel,
                onCancel: {
                    viewModel.clearError()
                    flow = .landing
                },
                onAdded: onDemoPlaylistAdded
            )
        }
    }
}

private enum CreatePlaylistFlow {
    case landing
    case xtream
    case m3u
    case demo
}

#Preview("Create Playlist Screen") {
    CreatePlaylistScreen(
        viewModel: CreatePlaylistViewModel(playlistService: AppContainer.live.playlistService),
        onDemoPlaylistAdded: {}
    )
}
