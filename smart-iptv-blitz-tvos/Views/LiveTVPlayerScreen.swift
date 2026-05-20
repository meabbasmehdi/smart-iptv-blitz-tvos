import AVKit
import SwiftUI

struct LiveTVPlayerScreen: View {
    let channel: LiveTVPlayerChannel
    let onBack: () -> Void

    @State private var player: AVPlayer?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
            } else {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.4)
            }
        }
        .onAppear {
            let player = AVPlayer(url: channel.url)
            self.player = player
            player.play()
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
        #if os(tvOS)
        .onExitCommand(perform: onBack)
        #endif
    }
}
