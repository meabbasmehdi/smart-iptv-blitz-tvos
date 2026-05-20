//
//  ContentView.swift
//  smart-iptv-blitz-tvos
//
//  Created by Abbas Mehdi on 14/05/2026.
//

import SwiftUI

struct ContentView: View {
    private let container: AppContainer

    @StateObject private var startupViewModel: AppStartupViewModel
    @StateObject private var disclaimerViewModel: DisclaimerViewModel
    @StateObject private var playlistsViewModel: PlaylistsViewModel
    @StateObject private var createPlaylistViewModel: CreatePlaylistViewModel
    @StateObject private var homeViewModel: HomeViewModel
    @StateObject private var liveTVViewModel: LiveTVViewModel

    init(container: AppContainer = .live) {
        self.container = container
        _startupViewModel = StateObject(
            wrappedValue: AppStartupViewModel(startupService: container.startupService)
        )
        _disclaimerViewModel = StateObject(
            wrappedValue: DisclaimerViewModel(
                disclaimerService: container.disclaimerService,
                preferences: container.preferences
            )
        )
        _playlistsViewModel = StateObject(
            wrappedValue: PlaylistsViewModel(playlistService: container.playlistService)
        )
        _createPlaylistViewModel = StateObject(
            wrappedValue: CreatePlaylistViewModel(playlistService: container.playlistService)
        )
        _homeViewModel = StateObject(
            wrappedValue: HomeViewModel(preferences: container.preferences)
        )
        _liveTVViewModel = StateObject(
            wrappedValue: LiveTVViewModel(service: container.liveTVService)
        )
    }

    var body: some View {
        ZStack {
            switch startupViewModel.route {
            case nil:
                SplashView(showStartButton: false, onStartClick: nil)
                    .transition(.opacity)
            case .some(.disclaimer):
                DisclaimerScreen(viewModel: disclaimerViewModel) {
                    startupViewModel.routeToPlaylists()
                }
                .transition(.opacity)
            case .some(.playlists):
                PlaylistGateScreen(
                    viewModel: playlistsViewModel,
                    onNeedsPlaylistCreation: startupViewModel.routeToCreatePlaylist,
                    onOpenHome: startupViewModel.routeToHome
                )
                .transition(.opacity)
            case .some(.createPlaylist):
                CreatePlaylistScreen(
                    viewModel: createPlaylistViewModel,
                    onDemoPlaylistAdded: startupViewModel.routeToHome
                )
                    .transition(.opacity)
            case .some(.home):
                HomeScreen(
                    viewModel: homeViewModel,
                    onOpenLiveTV: startupViewModel.routeToLiveTV
                )
                    .onAppear {
                        homeViewModel.refreshActivePlaylist()
                    }
                    .transition(.opacity)
            case .some(.liveTV):
                LiveTVCategoriesScreen(
                    viewModel: liveTVViewModel,
                    onOpenPlayer: startupViewModel.routeToPlayer,
                    onBack: startupViewModel.routeToHome
                )
                .transition(.opacity)
            case .some(.player):
                if let channel = liveTVViewModel.playerChannel {
                    LiveTVPlayerScreen(channel: channel) {
                        liveTVViewModel.clearPlayer()
                        startupViewModel.routeToLiveTV()
                    }
                    .transition(.opacity)
                } else {
                    LiveTVCategoriesScreen(
                        viewModel: liveTVViewModel,
                        onOpenPlayer: startupViewModel.routeToPlayer,
                        onBack: startupViewModel.routeToHome
                    )
                    .transition(.opacity)
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: startupViewModel.route)
        .task {
            await startupViewModel.startIfNeeded()
        }
    }
}

#Preview {
    ContentView()
}
